{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.netbox;
  secrets = config.mjm.services.netbox.vault.keys;
in
{
  options.mjm.netbox = {
    enable = mkEnableOption "netbox";
  };

  config = mkIf cfg.enable {
    mjm.services.netbox = {
      vault = {
        enable = true;
        keys.secret_key.owner = "netbox";
      };
    };
    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = config.services.netbox.dataDir;
        user = "netbox";
        group = "netbox";
      }
    ];

    vault-secrets.wantedBy = [
      "netbox.service"
      "netbox-rq.service"
      "netbox-housekeeping.service"
    ];

    ingress.virtualHosts.netbox = {
      upstream.service.name = "netbox";
    };

    services.netbox = {
      enable = true;
      package = pkgs.netbox_4_1;
      listenAddress = "[::]";
      settings = {
        ALLOWED_HOSTS = [
          "netbox.midna.dev"
          "netbox.service.consul"
          "10.0.2.41"
          "[2601:282:167f:d062:acf4:f0ff:feb0:3126]"
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
      secretKeyFile = secrets.secret_key.path;
    };

    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
      '';
      virtualHosts.":8000" = {
        extraConfig = ''
          encode gzip zstd
          root * /var/lib/netbox/

          @not_static {
            not path /static/*
          }

          reverse_proxy @not_static 127.0.0.1:${toString config.services.netbox.port}
          file_server
        '';
      };
    };

    users.users.caddy.extraGroups = [ "netbox" ];

    networking.firewall.allowedTCPPorts = [ 8000 ];

    services.consul.services.netbox = {
      port = 8000;
      metrics.enable = true;
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) netbox_4_1;
    };
  };
}
