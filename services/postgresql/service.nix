{
  vault.services.postgresql = {
    paths."kv/data/postgresql".capabilities = [ "read" ];
    hosts = [
      "chaos"
      "leto"
      "helios"
    ];
  };
}
