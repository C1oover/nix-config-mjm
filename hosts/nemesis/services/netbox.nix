{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  services.netbox = {
    enable = true;
    listenAddress = "0.0.0.0";
    settings = {
      ALLOWED_HOSTS = [
        "netbox.home.mattmoriarity.com"
        "netbox.service.consul"
        "10.0.2.45"
      ];
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
        servers = { "127.0.0.1:${toString config.services.netbox.port}" = { }; };
      };
    };
    virtualHosts."netbox" = {
      serverName = "_";
      default = true;
      locations."/static/" = {
        alias = config.services.netbox.settings.STATIC_ROOT + "/";
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

  systemd.tmpfiles.rules = [ "d /run/secrets/netbox 0700 netbox netbox - -" ];

  services.vault-agent.instances.netbox.settings =
    let
      va = import ../../../lib/vault-agent.nix { inherit pkgs; };
    in
    va.mkConfig {
      roleId = "e2aed065-6308-cc74-91a5-2613f3f1199a";
      secretIdFile = config.age.secrets."netbox-approle-secret-id".path;
      templates = [
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
