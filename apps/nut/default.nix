{
  vault.policies.nut-client = {
    paths."kv/data/nut/client".capabilities = [ "read" ];
    approles = [
      "brontes"
      "steropes"
    ];
  };

  vault.policies.nut-server = {
    paths."kv/data/nut".capabilities = [ "read" ];
    paths."kv/data/nut/client".capabilities = [ "read" ];
    approles = [ "arges" ];
  };
}
