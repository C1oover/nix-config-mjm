{
  vault.policies.loki = {
    paths."kv/data/loki".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
