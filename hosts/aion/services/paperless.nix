{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    extraConfig = {
      PAPERLESS_REDIS = "redis://redis.service.consul:6379";
      PAPERLESS_DBHOST = "postgresql.service.consul";
      PAPERLESS_DBPORT = "5432";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBSSLMODE = "disable";
      PAPERLESS_URL = "https://paperless.home.mattmoriarity.com";
      PAPERLESS_ALLOWED_HOSTS = "paperless.service.consul";
      PAPERLESS_ENABLE_HTTP_REMOTE_USER = "true";
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.paperless.port
  ];

  services.consul.extraConfigFiles = [
    (toString (format.generate "paperless.json" {
      service = {
        id = "paperless:${config.networking.hostName}";
        name = "paperless";
        port = config.services.paperless.port;
      };
    }))
  ];

  systemd.tmpfiles.rules = [
    "d /run/secrets/paperless 0700 paperless paperless - -"
  ];

  systemd.services.paperless-vault-agent =
    let
      roleId = pkgs.writeText "paperless-role-id" "11a736d8-ef30-f7aa-1d1e-72029ce45fb4";
      restartScript = pkgs.writeShellScriptBin "paperless-restart" ''
        set -e

        systemctl restart paperless-scheduler.service
        systemctl restart paperless-task-queue.service
        systemctl restart paperless-consumer.service
        systemctl restart paperless-web.service
      '';
      configFile = format.generate "vault-agent.json" {
        vault.address = "http://vault.service.consul:8200";
        auto_auth.method = [
          {
            type = "approle";
            config = {
              remove_secret_id_file_after_reading = false;
              role_id_file_path = "${roleId}";
              secret_id_file_path = config.age.secrets."paperless-approle-secret-id".path;
            };
          }
        ];
        template = [
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
    in
    {
      # leave this turned off to avoid creating buttloads of users
      enable = false;

      description = "Vault agent to provide rotating database credentials for Paperless";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.glibc ];

      startLimitIntervalSec = 60;
      startLimitBurst = 3;
      serviceConfig = {
        ExecStart = "${pkgs.vault}/bin/vault agent -config=${configFile}";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGHUP $MAINPID";
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "read-only";
        NoNewPrivileges = true;
        KillSignal = "SIGINT";
        TimeoutStopSec = "30s";
        Restart = "on-failure";
      };
    };

  systemd.services.paperless-scheduler.serviceConfig.EnvironmentFile = "/run/secrets/paperless/paperless.env";
  systemd.services.paperless-task-queue.serviceConfig.EnvironmentFile = "/run/secrets/paperless/paperless.env";
  systemd.services.paperless-consumer.serviceConfig.EnvironmentFile = "/run/secrets/paperless/paperless.env";
  systemd.services.paperless-web.serviceConfig.EnvironmentFile = "/run/secrets/paperless/paperless.env";
  systemd.services.paperless-download-nltk-data.serviceConfig.ProtectHostname = false;

  # TODO: sshd config to accept uploads from scanner

  age.secrets."paperless-approle-secret-id" = {
    file = ../../../secrets/paperless-approle-secret-id.age;
    owner = "paperless";
  };
}
