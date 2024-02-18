{
  vault.policies.garage = {
    paths."kv/data/garage".capabilities = [ "read" ];
    approles = [
      "leto"
      "chaos"
      "helios"
    ];
  };
}
