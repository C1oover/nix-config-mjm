{
  ingress.virtualHosts.homelab = {
    upstream.service.name = "homelab";
  };

  vault.policies.homelab = {
    paths = {
      "kv/data/paperless/client".capabilities = [ "read" ];
      "kv/data/homelab".capabilities = [ "read" ];
      "kv/data/taskwarrior".capabilities = [ "read" ];
    };
    approles = [ "leto" ];
  };

  # already has it for making backups, but just in case things move around
  vault.policies.restic.approles = [ "leto" ];
}
