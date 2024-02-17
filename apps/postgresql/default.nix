{
  vault.policies.postgresql.paths = {
    "kv/data/postgresql".capabilities = [ "read" ];
  };

  vault.approles.roles.leto.tokenPolicies = [ "postgresql" ];
}
