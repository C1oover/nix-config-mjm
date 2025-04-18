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

  clientId = "puow6sn22OE8UBLQT0RPYavisozbEY6Kn4y5a4vpgEHEykETK902zILI0cew4guQ";
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

      enableAuthProxy = false;
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
        REMOTE_AUTH_BACKEND = "social_core.backends.open_id_connect.OpenIdConnectAuth";
        # TODO fix this by configuring the X-Forwarded-Proto to come through properly
        SOCIAL_AUTH_REDIRECT_IS_HTTPS = true;
        SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = "https://auth.midna.dev";
        SOCIAL_AUTH_OIDC_KEY = clientId;
        SOCIAL_AUTH_OIDC_SCOPE = [ "groups" ];
        REMOTE_AUTH_GROUP_SYNC_ENABLED = true;
        REMOTE_AUTH_SUPERUSER_GROUPS = [ "admins" ];
        REMOTE_AUTH_STAFF_GROUPS = [ "admins" ];
      };
      # even though we override extraConfig to not use this, it will still cause an eval error
      # because the upstream module tries to use it
      secretKeyFile = "/dev/null";
      extraConfig = mkForce ''
        import os
        creds_dir = os.environ["CREDENTIALS_DIRECTORY"]
        with open(f'{creds_dir}/netbox_secret_key', "r") as file:
            SECRET_KEY = file.readline()
        with open(f'{creds_dir}/netbox_managed__oidc_client_secret', "r") as file:
            SOCIAL_AUTH_OIDC_SECRET = file.readline()
      '';
    };

    mjm.authelia.oidcClients.netbox = {
      name = "NetBox";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$gwBe7ee4a2veQ2L5xyOUEw$Z08vF2YogFlhWPnuWsNg82Z4qm7ijKshLVYugEei3CU";
      redirectUris = [ "https://netbox.midna.dev/oauth/complete/oidc/" ];
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
          serviceConfig = {
            LoadCredential = [
              "netbox_secret_key:/run/netbox-creds.sock"
              "netbox_managed__oidc_client_secret:/run/netbox-creds.sock"
            ];
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
        allowIngress = true;
        allowMetrics = true;
      };
    };

    users.users.caddy.extraGroups = [ "netbox" ];

    services.consul.services.netbox = {
      port = 8000;
      metrics.enable = true;
      metrics.tls = true;
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) netbox_4_1;
    };
  };
}
