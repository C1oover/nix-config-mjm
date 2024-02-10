{
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

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  services.consul.services.grafana = {
    port = 3000;

    meta.metrics_path = "/metrics";

    checks = [
      {
        name = "grafana is ready";
        http = "http://localhost:3000/api/health";
        interval = "15s";
        timeout = "10s";
      }
    ];
  };
}
