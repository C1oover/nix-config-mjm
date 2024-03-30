{
  vault.policies.vault-backup = {
    paths = {
      "sys/leader".capabilities = [ "read" ];
      "sys/storage/raft/snapshot".capabilities = [ "read" ];
    };
    approles = [ "vault-backup" ];
  };
}
