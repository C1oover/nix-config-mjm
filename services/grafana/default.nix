{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.grafana;
  secrets = config.mjm.services.grafana.vault.keys;
  clientId = "7BReUARtsRcF6ypjiA4DcJ3E6fJNjzwheH5Tj1HCLoqfXCQSLHxZJHQ7bAV9U0aU";
in
{
  options.mjm.grafana = {
    enable = mkEnableOption "grafana";
  };

  imports = [
    ./loki.nix
    ./tempo.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.grafana = {
      postgresql.enable = true;
      vault = {
        enable = true;
        keys = {
          "managed/oidc_client_secret".owner = "grafana";
        };
      };
    };

    ingress.virtualHosts.graphs = {
      upstream = {
        service.name = "grafana";
        tls.enable = true;
      };

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          protocol = "socket";
          socket = "/run/grafana/server.sock";
          socket_mode = "0666";
          domain = "graphs.midna.dev";
          root_url = "https://graphs.midna.dev";
        };

        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
        };

        auth = {
          disable_login_form = true;
        };

        "auth.generic_oauth" = {
          enabled = true;
          name = "Authelia";
          icon = "signin";
          client_id = clientId;
          client_secret = "$__file{${secrets."managed/oidc_client_secret".path}}";
          scopes = "openid profile email groups";
          auth_url = "https://auth.midna.dev/api/oidc/authorization";
          token_url = "https://auth.midna.dev/api/oidc/token";
          api_url = "https://auth.midna.dev/api/oidc/userinfo";
          login_attribute_path = "preferred_username";
          groups_attribute_path = "groups";
          name_attribute_path = "name";
          use_pkce = true;

          # only enterprise gets a proper mapping from groups to roles
          skip_org_role_sync = true;
        };
      };
    };

    mjm.authelia.oidcClients.grafana = {
      name = "Grafana";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$LExwz3BrD2Cu5o1ur61RIw$W4kCJsEG+VuCxeEOI689IEMoiE2r5G2Nwrc+q4fHU0c";
      requirePkce = true;
      redirectUris = [ "https://graphs.midna.dev/login/generic_oauth" ];
    };

    mjm.networkd.macvlan.enable = true;

    systemd.services.grafana = {
      bindsTo = [ "netns-bridge@grafana.service" ];
      after = [ "netns-bridge@grafana.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/grafana";
    };

    mjm.spire.tunnels = {
      grafana = {
        mode = "server";
        namespace = "grafana";
        port = 3000;
        target = "unix:/run/grafana/server.sock";
        allowIngress = true;
        allowMetrics = true;
      };
      grafana-loki = {
        mode = "client";
        namespace = "grafana";
        port = 3100;
        target = "loki.service.consul:3103";
        service = "loki";
      };
      grafana-tempo = {
        mode = "client";
        namespace = "grafana";
        port = 3200;
        target = "tempo.service.consul:3200";
        service = "tempo";
      };
      grafana-prometheus = {
        mode = "client";
        namespace = "grafana";
        port = 9090;
        target = "prometheus.service.consul:9090";
        service = "prometheus";
      };
    };

    services.consul.services.grafana = {
      port = 3000;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/api/health";
        http.socket = "/run/grafana/server.sock";
      };
    };

    deployment.tests = {
      grafana-basic = pkgs.nixosTests.grafana.basic;
    };
  };
}
