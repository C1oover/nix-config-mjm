{ config, ... }:
{
  vault.services.postgresql = {
    paths."kv/data/postgresql".capabilities = [ "read" ];
    commonPolicies = [ "backups" ];
    hosts = [
      "chaos"
      "leto"
      "helios"
    ];
  };
}
