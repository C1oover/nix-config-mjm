{
  vault.policies.postgresql = {
    paths."kv/data/postgresql".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
