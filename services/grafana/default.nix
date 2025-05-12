{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.grafana;
  clientId = "7BReUARtsRcF6ypjiA4DcJ3E6fJNjzwheH5Tj1HCLoqfXCQSLHxZJHQ7bAV9U0aU";
in
{
  options.mjm.grafana = {
    enable = mkEnableOption "grafana";
  };

  config = mkIf cfg.enable {
    mjm.services.grafana = {
      postgresql.enable = true;
      vault.enable = true;
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
          client_secret = "$__file{/run/credentials/grafana.service/grafana_managed__oidc_client_secret}";
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
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/grafana";
        LoadCredential = [ "grafana_managed__oidc_client_secret:/run/grafana-creds.sock" ];
      };
    };

    mjm.spire.tunnels = {
      grafana = {
        mode = "server";
        listen.port = 3000;
        target.socket = "/run/grafana/server.sock";
        allowIngress = true;
        allowMetrics = true;
      };
      grafana-loki = {
        mode = "client";
        listen.port = 3100;
        listen.namespace = "grafana";
        target.port = 3103;
        target.service = "loki";
      };
      grafana-tempo = {
        mode = "client";
        listen.port = 3200;
        listen.namespace = "grafana";
        target.service = "tempo";
        target.port = 3200;
      };
      grafana-prometheus = {
        mode = "client";
        listen.port = 9090;
        listen.namespace = "grafana";
        target.port = 9090;
        target.service = "prometheus";
      };
      grafana-alertmanager = {
        mode = "client";
        listen.port = 9093;
        listen.namespace = "grafana";
        target.port = 9093;
        target.service = "alertmanager";
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
