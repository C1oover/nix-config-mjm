{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    flip
    genAttrs
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    ;
  cfg = config.mjm.netbox;
in
{
  options.mjm.netbox = {
    enable = mkEnableOption "netbox";
  };

  config = mkIf cfg.enable {
    mjm.services.netbox = {
      vault = {
        enable = true;
        useSpiffeIdentity = true;
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

    ingress.virtualHosts.netbox = {
      upstream = {
        service.name = "netbox";
        tls.enable = true;
      };
    };

    services.netbox = {
      enable = true;
      package = pkgs.netbox_4_1;
      unixSocket = "/run/netbox/server.sock";
      settings = {
        ALLOWED_HOSTS = [
          "netbox.midna.dev"
          "netbox.service.consul"
          "10.0.2.41"
          "[${config.mjm.ipv6Prefix}:acf4:f0ff:feb0:3126]"
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
      # even though we override extraConfig to not use this, it will still cause an eval error
      # because the upstream module tries to use it
      secretKeyFile = "/dev/null";
      extraConfig = mkForce ''
        import os
        with open(f'{os.environ["CREDENTIALS_DIRECTORY"]}/netbox_secret_key', "r") as file:
            SECRET_KEY = file.readline()
      '';
    };

    systemd.services = mkMerge [
      {
        netbox = {
          serviceConfig.RuntimeDirectory = "netbox";
        };
        caddy = {
          serviceConfig.RuntimeDirectory = "caddy";
        };
      }
      (flip genAttrs
        (_: {
          # bindsTo = [ "netns-bridge@netbox.service" ];
          # after = [ "netns-bridge@netbox.service" ];
          serviceConfig = {
            # NetworkNamespacePath = "/run/netns/netbox";
            LoadCredential = [ "netbox_secret_key:/run/netbox-creds.sock" ];
          };
        })
        [
          "netbox"
          "netbox-rq"
          "netbox-housekeeping"
        ]
      )
    ];

    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
      '';
      virtualHosts."http://" = {
        listenAddresses = [ "unix//run/caddy/netbox.sock|0222" ];
        extraConfig = ''
          encode gzip zstd
          root * /var/lib/netbox/

          @not_static {
            not path /static/*
          }

          reverse_proxy @not_static unix/${config.services.netbox.unixSocket}
          file_server
        '';
      };
    };

    mjm.spire.tunnels = {
      netbox = {
        mode = "server";
        port = 8000;
        target = "unix:/run/caddy/netbox.sock";
      };
    };

    users.users.caddy.extraGroups = [ "netbox" ];

    services.consul.services.netbox = {
      port = 8000;
      metrics.enable = true;
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) netbox_4_1;
    };
  };
}
