{
  vault.policies.restic.paths = {
    "kv/data/restic".capabilities = [ "read" ];
  };

  vault.approles.roles.leto.tokenPolicies = [ "restic" ];
}
