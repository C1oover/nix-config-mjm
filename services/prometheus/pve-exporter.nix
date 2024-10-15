{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.prometheus;
in
{
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pythonFinal: pythonPrev: {
            proxmoxer = pythonPrev.proxmoxer.overridePythonAttrs (oldAttrs: {
              nativeCheckInputs = oldAttrs.nativeCheckInputs ++ [
                pythonFinal.pynacl
              ];
            });
          })
        ];
      })
    ];

    services.prometheus.exporters.pve = {
      enable = true;
      environmentFile = config.vault-secrets.templates.pve-env.path;
    };

    vault-secrets.wantedBy = [ "prometheus-pve-exporter.service" ];
    vault-secrets.templates.pve-env.text = ''
      # the certs are valid, but not for the proxmox.service.consul domain
      PVE_VERIFY_SSL=false

      PVE_USER=prometheus@pam
      PVE_TOKEN_NAME=metrics
      {{ with secret "kv/prod/services/prometheus" }}
      PVE_TOKEN_VALUE={{ .Data.data.pve_metrics_token }}
      {{ end }}
    '';
  };
}
