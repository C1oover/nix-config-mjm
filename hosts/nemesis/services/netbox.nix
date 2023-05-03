{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  services.netbox-external = {
    enable = true;
    listenAddress = "0.0.0.0";
    settings = {
      ALLOWED_HOSTS = [ "netbox.home.mattmoriarity.com" "netbox.service.consul" ];
      REDIS = {
        tasks = {
          HOST = "redis.service.consul";
          PORT = 6379;
          DATABASE = 1;
        };
        caching = {
          HOST = "redis.service.consul";
          PORT = 6379;
          DATABASE = 2;
        };
      };
      CORS_ORIGIN_ALLOW_ALL = false;
      CORS_ORIGIN_WHITELIST = [
        "https://netbox.home.mattmoriarity.com"
      ];
      CSRF_TRUSTED_ORIGINS = [
        "https://netbox.home.mattmoriarity.com"
        "http://netbox.service.consul:8000"
      ];
      METRICS_ENABLED = true;
      REMOTE_AUTH_ENABLED = true;
      REMOTE_AUTH_BACKEND = "netbox.authentication.RemoteUserBackend";
      REMOTE_AUTH_HEADER = "HTTP_REMOTE_USER";
      REMOTE_AUTH_AUTO_CREATE_USER = true;
      REMOTE_AUTH_GROUP_HEADER = "HTTP_REMOTE_GROUPS";
      REMOTE_AUTH_GROUP_SYNC_ENABLED = true;
      REMOTE_AUTH_GROUP_SEPARATOR = ",";
      REMOTE_AUTH_SUPERUSER_GROUPS = [ "admins" ];
      REMOTE_AUTH_STAFF_GROUPS = [ "admins" ];
    };
    secretKeyFile = config.age.secrets."netbox-secret-key".path;
    extraConfig = ''
      import json
      with open("/run/secrets/netbox/db-config.json", "r") as file:
          DATABASE = json.load(file)
    '';
  };

  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    defaultHTTPListenPort = 8000;
    upstreams = {
      netbox = {
        servers = { "127.0.0.1:${toString config.services.netbox-external.port}" = { }; };
      };
    };
    virtualHosts."netbox" = {
      serverName = "_";
      default = true;
      locations."/static/" = {
        alias = config.services.netbox-external.settings.STATIC_ROOT;
      };
      locations."/" = {
        proxyPass = "http://netbox";
        recommendedProxySettings = true;
      };
    };
  };

  users.users.nginx.extraGroups = [ "netbox" ];

  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
  ];

  services.consul.extraConfigFiles = [
    (toString (format.generate "netbox.json" {
      service = {
        id = "netbox:${config.networking.hostName}";
        name = "netbox";
        port = config.services.nginx.defaultHTTPListenPort;

        meta = {
          metrics_path = "/metrics";
        };
      };
    }))
  ];

  systemd.tmpfiles.rules = [
    "d /run/secrets/netbox 0700 netbox netbox - -"
  ];

  systemd.services.netbox-vault-agent =
    let
      roleId = pkgs.writeText "netbox-role-id" "e2aed065-6308-cc74-91a5-2613f3f1199a";
      configFile = format.generate "vault-agent.json" {
        vault.address = "http://vault.service.consul:8200";
        auto_auth.method = [
          {
            type = "approle";
            config = {
              remove_secret_id_file_after_reading = false;
              role_id_file_path = "${roleId}";
              secret_id_file_path = config.age.secrets."netbox-approle-secret-id".path;
            };
          }
        ];
        template = [
          {
            contents = ''
              {{ with secret "database/creds/netbox" }}
              {
                "NAME": "netbox",
                "USER": {{ .Data.username | toJSON }},
                "PASSWORD": {{ .Data.password | toJSON }},
                "HOST": "postgresql.service.consul",
                "CONN_MAX_AGE": 300
              }
              {{ end }}
            '';
            destination = "/run/secrets/netbox/db-config.json";
            command = "systemctl restart netbox.service";
          }
        ];
      };
    in
    {
      description = "Vault agent to provide rotating database credentials for NetBox";

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

  age.secrets = {
    "netbox-secret-key" = {
      file = ../../../secrets/netbox-secret-key.age;
      owner = "netbox";
    };
    "netbox-approle-secret-id" = {
      file = ../../../secrets/netbox-approle-secret-id.age;
      owner = "netbox";
    };
  };
}
