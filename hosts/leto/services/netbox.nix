{
  config,
  lib,
  pkgs,
  ...
}: {
  # The NetBox module only really supports running these locally, but I don't want to do that.
  services.redis.servers.netbox.enable = lib.mkForce false;
  services.postgresql.enable = lib.mkForce false;

  services.netbox = {
    enable = true;
    package = pkgs.netbox_3_6;
    listenAddress = "[::]";
    settings = {
      ALLOWED_HOSTS = [
        "netbox.midna.dev"
        "netbox.home.mattmoriarity.com"
        "netbox.service.consul"
        "10.0.2.41"
      ];
      DATABASE = lib.mkForce {};
      REDIS = lib.mkForce {
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
        "https://netbox.midna.dev"
        "https://netbox.home.mattmoriarity.com"
      ];
      CSRF_TRUSTED_ORIGINS = [
        "https://netbox.midna.dev"
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
      REMOTE_AUTH_SUPERUSER_GROUPS = ["admins"];
      REMOTE_AUTH_STAFF_GROUPS = ["admins"];
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
        servers = {"127.0.0.1:${toString config.services.netbox.port}" = {};};
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

  users.users.nginx.extraGroups = ["netbox"];

  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
  ];

  services.consul.services.netbox = {
    port = config.services.nginx.defaultHTTPListenPort;
    meta.metrics_path = "/metrics";
  };

  systemd.tmpfiles.rules = ["d /run/secrets/netbox 0700 netbox netbox - -"];

  services.vault-agent.instances.main.templates = [
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
      exec = {
        command = "systemctl restart netbox.service";
        timeout = "5m";
      };
    }
  ];

  age.secrets = {
    "netbox-secret-key" = {
      file = ../../../secrets/netbox-secret-key.age;
      owner = "netbox";
    };
  };
}
