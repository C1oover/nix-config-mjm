{
  vault.policies.postgresql = {
    paths."kv/data/postgresql".capabilities = [ "read" ];
    approles = [
      "chaos"
      "leto"
      "helios"
    ];
  };
}
