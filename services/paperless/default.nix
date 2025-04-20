{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkAfter mkEnableOption mkIf;
  cfg = config.mjm.paperless;

  scannerPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1NXtzg50EbpzudswkjUkxllahH+F54h6MnDoXarftqlHc26M46M5IPQeRpn5F4BLGWs94UNFyod4d7KNhRYXxh2G+gsJcDTREdUR7eKu5CfaFnB2sge8VJM8KwxbURXHlxNF2xha0lIg8HdfSIznogAGqcUYahTJAUdKB1A4UJ9DzHp1Mrlrk3o04TvokRmS18kPM39nstneqHRVC1TPf83QV3tAYBz2iayifH714KTcItflUe5IqDUhBfNURhOnhG0szfK2qtykdg+7/wu0Ah3HOlbfLybx2eAA048kyBiFpllFIGqoO0hN8w7wmMuQ6okxs3tssz7W+dGi5HDob root@BR5CF370C29B2A";

  clientId = "LijoxTI8E2n5IeFZcFxrQcC94ENIqkzXzhh93LpKGMBCQzMDnmsQ3c6zWXjUXJe3";
in
{
  options.mjm.paperless = {
    enable = mkEnableOption "paperless";
  };

  config = mkIf cfg.enable {
    mjm.services.paperless = {
      postgresql.enable = true;
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };
    mjm.state.directories = [
      {
        directory = config.services.paperless.dataDir;
        inherit (config.services.paperless) user;
        group = "paperless";
      }
    ];

    ingress.virtualHosts.paper = {
      upstream.service.name = "paperless";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.paperless = {
      enable = true;
      address = "::";
      settings = {
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_URL = "https://paper.midna.dev";
        PAPERLESS_ALLOWED_HOSTS = "paperless.service.consul,localhost";
        PAPERLESS_OCR_USER_ARGS = {
          invalidate_digital_signatures = true;
        };
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
        PAPERLESS_DISABLE_REGULAR_LOGIN = true;
        PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
      };
      environmentFile = config.vault-secrets.templates.paperless-env.path;
    };

    mjm.authelia.oidcClients.paperless = {
      name = "Paperless";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$0Rg1T9HOd4EWIf6LrHDCDQ$95ihO+jnuTMLsSJrstHTJx12SUpZmExHUYpAeqtdheg";
      requirePkce = true;
      redirectUris = [ "https://paper.midna.dev/accounts/oidc/authelia/login/callback/" ];
    };

    vault-secrets.wantedBy = [
      "paperless-scheduler.service"
      "paperless-task-queue.service"
      "paperless-consumer.service"
      "paperless-web.service"
    ];
    vault-secrets.templates.paperless-env.text = ''
      {{ with secret "kv/prod/services/paperless/managed" }}
      PAPERLESS_SOCIALACCOUNT_PROVIDERS=${
        builtins.toJSON {
          openid_connect = {
            SCOPE = [
              "openid"
              "profile"
              "email"
            ];
            OAUTH_PKCE_ENABLED = true;
            APPS = [
              {
                provider_id = "authelia";
                name = "Authelia";
                client_id = clientId;
                secret = "{{ .Data.data.oidc_client_secret }}";
                settings = {
                  server_url = "https://auth.midna.dev";
                  token_auth_method = "client_secret_basic";
                };
              }
            ];
          };
        }
      }
      {{ end }}
    '';

    # wait for postgresql
    # the scheduler is the first service that needs the database
    systemd.services.paperless-scheduler.after = [ "postgresql.service" ];

    networking.firewall.allowedTCPPorts = [ config.services.paperless.port ];

    services.consul.services.paperless = {
      inherit (config.services.paperless) port;

      checks.up = {
        http.path = "/";
        intervalSeconds = 30;
      };
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
      paths = [ "/var/lib/paperless/media/documents" ];
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) paperless;
    };
  };
}
