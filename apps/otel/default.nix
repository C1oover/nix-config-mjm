{
  vault.policies.otel-collector = {
    paths."kv/data/honeycomb".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
