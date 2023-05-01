{ pkgs, ... }: {
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "consul";
    listenerExtraConfig = ''
      telemetry {
        unauthenticated_metrics_access = true
      }
    '';
    extraConfig = ''
      ui = true

      telemetry {
        disable_hostname = true
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    8200
    8201
  ];
}
