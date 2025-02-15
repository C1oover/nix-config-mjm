{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.grafana;
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
    };

    ingress.virtualHosts.graphs = {
      upstream.service.name = "grafana";
      useIPv4Proxy = true;
    };

    vault.services.grafana = { };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          domain = "graphs.midna.dev";
        };

        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
        };

        "auth.proxy" = {
          enabled = true;
          header_name = "Remote-User";
          headers = "Email:Remote-Email";
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
