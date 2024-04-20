{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.netbox;
in
{
  options.mjm.netbox = {
    enable = mkEnableOption "netbox";
  };

  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = config.services.netbox.dataDir;
        user = "netbox";
        group = "netbox";
      }
    ];
    deployment.tags = [ "svc-netbox" ];

    services.netbox = {
      enable = true;
      # TODO remove override when rq builds
      package = pkgs.netbox_3_7.override {
        python3 = pkgs.python3 // {
          pkgs = pkgs.python3.pkgs.overrideScope (
            final: prev: { rq = prev.rq.overridePythonAttrs { doCheck = false; }; }
          );
        };
      };
      listenAddress = "[::]";
      settings = {
        ALLOWED_HOSTS = [
          "netbox.midna.dev"
          "netbox.service.consul"
          "10.0.2.41"
        ];
        CORS_ORIGIN_ALLOW_ALL = false;
        CORS_ORIGIN_WHITELIST = [ "https://netbox.midna.dev" ];
        CSRF_TRUSTED_ORIGINS = [
          "https://netbox.midna.dev"
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
      secretKeyFile = config.vault-secrets.services.netbox.keys.secret_key.path;
    };

    vault-secrets.wantedBy = [
      "netbox.service"
      "netbox-rq.service"
      "netbox-housekeeping.service"
    ];
    vault-secrets.services.netbox = {
      keys.secret_key.owner = "netbox";
    };

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      defaultHTTPListenPort = 8000;
      upstreams = {
        netbox = {
          servers = {
            "127.0.0.1:${toString config.services.netbox.port}" = { };
          };
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

    networking.firewall.allowedTCPPorts = [ config.services.nginx.defaultHTTPListenPort ];

    services.consul.services.netbox = {
      port = config.services.nginx.defaultHTTPListenPort;
      meta.metrics_path = "/metrics";
    };
  };
}
