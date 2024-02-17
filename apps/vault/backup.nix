{
  vault.policies.vault-backup.paths = {
    "sys/leader".capabilities = [ "read" ];
    "sys/storage/raft/snapshot".capabilities = [ "read" ];
  };

  vault.approles.roles.vault-backup.tokenPolicies = [ "vault-backup" ];
}
