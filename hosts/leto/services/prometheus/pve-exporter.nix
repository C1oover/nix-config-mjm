{ config, ... }:
{
  services.prometheus.exporters.pve = {
    enable = true;
    environmentFile = config.vault-secrets.templates.pve-env.path;
  };

  systemd.services.prometheus-pve-exporter.after = [ "render-vault-secrets.service" ];

  vault-secrets.templates.pve-env.text = ''
    # the certs are valid, but not for the proxmox.service.consul domain
    PVE_VERIFY_SSL=false

    PVE_USER=prometheus@pam
    PVE_TOKEN_NAME=metrics
    {{ with secret "kv/proxmox" }}
    PVE_TOKEN_VALUE={{ .Data.data.metrics_token }}
    {{ end }}
  '';
}
