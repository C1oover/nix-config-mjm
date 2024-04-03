{ config, ... }:
{
  vault.services.vault = {
    paths = {
      "sys/leader".capabilities = [ "read" ];
      "sys/storage/raft/snapshot".capabilities = [ "read" ];
    };
    hosts = [
      "megaera"
      "tisiphone"
      "alecto"
    ];
  };

  vault.policies.common-backups.approles = config.vault.services.vault.hosts;
}
