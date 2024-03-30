{
  ingress.virtualHosts.graphs = {
    upstream.service.name = "grafana";
  };

  vault.services.grafana.hosts = [ "leto" ];
}
