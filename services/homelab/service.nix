{
  ingress.virtualHosts.homelab = {
    upstream.service.name = "homelab";
  };

  vault.services.homelab.hosts = [ "leto" ];

  # already has it for making backups, but just in case things move around
  vault.policies.restic.approles = [ "leto" ];
}
