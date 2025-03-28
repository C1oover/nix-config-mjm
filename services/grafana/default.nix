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
      upstream.service.name = "grafana";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
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
          client_id = "7BReUARtsRcF6ypjiA4DcJ3E6fJNjzwheH5Tj1HCLoqfXCQSLHxZJHQ7bAV9U0aU";
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

    networking.firewall.allowedTCPPorts = [ 3000 ];

    services.consul.services.grafana = {
      port = 3000;
      metrics.enable = true;

      checks.up = {
        http.path = "/api/health";
      };
    };

    deployment.tests = {
      grafana-basic = pkgs.nixosTests.grafana.basic;
    };
  };
}
