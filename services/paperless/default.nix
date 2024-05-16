{ config, lib, ... }:
let
  inherit (lib) mkAfter mkEnableOption mkIf;
  cfg = config.mjm.paperless;

  scannerPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1NXtzg50EbpzudswkjUkxllahH+F54h6MnDoXarftqlHc26M46M5IPQeRpn5F4BLGWs94UNFyod4d7KNhRYXxh2G+gsJcDTREdUR7eKu5CfaFnB2sge8VJM8KwxbURXHlxNF2xha0lIg8HdfSIznogAGqcUYahTJAUdKB1A4UJ9DzHp1Mrlrk3o04TvokRmS18kPM39nstneqHRVC1TPf83QV3tAYBz2iayifH714KTcItflUe5IqDUhBfNURhOnhG0szfK2qtykdg+7/wu0Ah3HOlbfLybx2eAA048kyBiFpllFIGqoO0hN8w7wmMuQ6okxs3tssz7W+dGi5HDob root@BR5CF370C29B2A";
in
{
  options.mjm.paperless = {
    enable = mkEnableOption "paperless";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pythonFinal: pythonPrev: {
            cramjam = pythonPrev.cramjam.overridePythonAttrs { doCheck = false; };
          })
        ];
      })
    ];

    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = config.services.paperless.dataDir;
        inherit (config.services.paperless) user;
        group = "paperless";
      }
    ];
    deployment.tags = [ "svc-paperless" ];

    services.paperless = {
      enable = true;
      address = "[::]";
      settings = {
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_URL = "https://paper.midna.dev";
        PAPERLESS_ALLOWED_HOSTS = "paperless.service.consul,localhost";
        PAPERLESS_ENABLE_HTTP_REMOTE_USER = true;
        PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
        PAPERLESS_OCR_USER_ARGS = {
          invalidate_digital_signatures = true;
        };
      };
    };

    # wait for postgresql
    # the scheduler is the first service that needs the database
    systemd.services.paperless-scheduler.after = [ "postgresql.service" ];

    services.postgresql = {
      ensureDatabases = [ "paperless" ];
      ensureUsers = [
        {
          name = "paperless";
          ensureDBOwnership = true;
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ config.services.paperless.port ];

    services.consul.services.paperless =
      let
        inherit (config.services.paperless) port;
      in
      {
        inherit port;

        checks = [
          {
            name = "paperless is up";
            http = "http://localhost:${toString port}/";
            interval = "30s";
            timeout = "5s";
          }
        ];
      };

    users.users.paperless.openssh.authorizedKeys.keys = [ scannerPublicKey ];

    services.openssh.settings.KexAlgorithms = [
      "sntrup761x25519-sha512@openssh.com"
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group-exchange-sha256"
      # this is the extra one added for compatibility with old SSH client
      "diffie-hellman-group14-sha1"
    ];
    services.openssh.settings.Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "umac-128-etm@openssh.com"
      "hmac-sha2-512"
      "hmac-sha2-256"
      "umac-128@openssh.com"
      # this is the extra one added for compatibility with old SSH client
      "hmac-sha1-96"
    ];
    # use mkAfter so the Match doesn't include other stuff
    services.openssh.extraConfig = mkAfter ''
      HostKeyAlgorithms +ssh-rsa
      PubkeyAcceptedAlgorithms +ssh-rsa
      Match User paperless
          X11Forwarding no
          AllowTcpForwarding no
          ForceCommand internal-sftp -u 0077 -d /var/lib/paperless/consume
    '';

    mjm.backups.paperless = {
      passwordFile = config.vault-secrets.services.paperless.keys.backup_password.path;
      paths = [ "/var/lib/paperless/media/documents" ];
    };

    vault-secrets.services.paperless = {
      keys.backup_password = { };
    };
  };
}
