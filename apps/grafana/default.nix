{
  ingress.virtualHosts.graphs = {
    upstream.service.name = "grafana";
  };

  vault.policies.tempo = {
    paths."kv/data/tempo".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
