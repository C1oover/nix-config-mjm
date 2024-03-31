{
  vault.policies.restic = {
    paths."kv/data/restic".capabilities = [ "read" ];
    approles = [
      "leto"
      "chaos"
      "helios"
    ];
  };

  vault.policies.common-backups = {
    paths."kv/data/prod/common/backups".capabilities = [ "read" ];
  };
}
