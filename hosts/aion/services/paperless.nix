{
  config,
  pkgs,
  lib,
  ...
}: let
  scannerPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVffhmmioPFJxQiP5OlssYk2EjHdeMxpV1OO2T3Qz3AjmMZsJunQdnpWV9wNEeG3uTwGmvDS4ejCoJvVy6kQMypFFjEqBegbK6N4HeMFYubxe2pp2NSZir1HEeHFYZSvrIjOKfN404WLpY/+TgM7UTQ5u5pUNmMPyyxLgZz/YJj9LVCo1IeYcv5hP3WSP1ixsJGBuUTgkVp4S/FouoHNoJ+jVbGSs0IjgBC77IzxH52Af/sXwb2MiRoM3HczEwnWuhiIniICCbjgju5hA0h1qCozRDx5jt6egKxzNxN7+tuW3S9t1D/sq/qn6hqyaTCHVxn9+2cw3KIXcK7LoduhX5 root@BR5CF370B3F03D";
in {
  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    extraConfig = {
      PAPERLESS_REDIS = "redis://redis.service.consul:6379";
      PAPERLESS_DBHOST = "postgresql.service.consul";
      PAPERLESS_DBPORT = "5432";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBSSLMODE = "disable";
      PAPERLESS_URL = "https://paper.midna.dev";
      PAPERLESS_ALLOWED_HOSTS = "paperless.service.consul,localhost";
      PAPERLESS_ENABLE_HTTP_REMOTE_USER = "true";
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.paperless.port
  ];

  services.consul.services.paperless = let
    inherit (config.services.paperless) port;
  in {
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

  systemd.tmpfiles.rules = ["d /run/secrets/paperless 0700 paperless paperless - -"];

  services.vault-agent.instances.paperless.settings = let
    restartScript = pkgs.writeShellScript "paperless-restart" ''
      set -e

      systemctl restart paperless-scheduler.service
      systemctl restart paperless-task-queue.service
      systemctl restart paperless-consumer.service
      systemctl restart paperless-web.service
    '';
    va = import ../../../lib/vault-agent.nix {inherit pkgs;};
  in
    va.mkConfig {
      roleId = "11a736d8-ef30-f7aa-1d1e-72029ce45fb4";
      secretIdFile = config.age.secrets."paperless-approle-secret-id".path;
      templates = [
        {
          contents = ''
            {{ with secret "database/creds/paperless" }}
            PAPERLESS_DBUSER={{ .Data.username }}
            PAPERLESS_DBPASS={{ .Data.password }}
            {{ end }}
            PAPERLESS_SECRET_KEY={{ with secret "kv/paperless" }}{{ .Data.data.secret_key }}{{ end }}
          '';
          destination = "/run/secrets/paperless/paperless.env";
          command = "${restartScript}";
        }
      ];
    };

  # Fix service configs so things actually are able to run.
  # Not sure if this is needed because this is running inside a container or what.
  systemd.services = {
    paperless-scheduler.serviceConfig = {
      EnvironmentFile = "/run/secrets/paperless/paperless.env";
      ProtectHostname = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      PrivateNetwork = lib.mkForce false;
      MemoryDenyWriteExecute = lib.mkForce false;
      SystemCallFilter = lib.mkForce null;
    };
    paperless-task-queue.serviceConfig = {
      EnvironmentFile = "/run/secrets/paperless/paperless.env";
      ProtectHostname = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
    paperless-consumer.serviceConfig = {
      EnvironmentFile = "/run/secrets/paperless/paperless.env";
      PrivateNetwork = lib.mkForce false;
      ProtectHostname = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
    paperless-web.serviceConfig = {
      EnvironmentFile = "/run/secrets/paperless/paperless.env";
      ProtectHostname = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
    paperless-download-nltk-data.serviceConfig = {
      ProtectHostname = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };

  users.users.paperless.openssh.authorizedKeys.keys = [scannerPublicKey];

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
  services.openssh.extraConfig = ''
    HostKeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    Match User paperless
        X11Forwarding no
        AllowTcpForwarding no
        ForceCommand internal-sftp -u 0077 -d /var/lib/paperless/consume
  '';

  age.secrets."paperless-approle-secret-id" = {
    file = ../../../secrets/paperless-approle-secret-id.age;
    owner = "paperless";
  };
}
