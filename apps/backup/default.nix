{
  vault.policies.common-backups = {
    paths."kv/data/prod/common/backups".capabilities = [ "read" ];
  };
}
