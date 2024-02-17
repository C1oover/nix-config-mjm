{
  vault.policies.restic = {
    paths."kv/data/restic".capabilities = [ "read" ];
    approles = [
      "leto"
      "chaos"
    ];
  };
}
