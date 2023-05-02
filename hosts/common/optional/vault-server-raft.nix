{ pkgs
, config
, ...
}: {
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "raft";
    storageConfig = ''
      node_id = "${config.networking.hostName}"
    '';
    listenerExtraConfig = ''
      cluster_address = "0.0.0.0:8201"
      telemetry {
        unauthenticated_metrics_access = true
      }
    '';
    extraConfig = ''
      api_addr = "http://{{ GetInterfaceIP \\"ens18\\" }}:8200"
      cluster_addr = "https://{{ GetInterfaceIP \\"ens18\\" }}:8201"
      disable_mlock = true
      ui = true

      telemetry {
        disable_hostname = true
      }
    '';
  };

  environment.etc."vault-migrate.hcl".text = ''
    storage_source "consul" {
      address = "127.0.0.1:8500"
      path = "vault"
    }

    storage_destination "raft" {
      path = "${config.services.vault.storagePath}"
      node_id = "${config.networking.hostName}"
    }

    cluster_addr = "https://{{ GetInterfaceIP \\"ens18\\" }}:8201"
  '';

  networking.firewall.allowedTCPPorts = [
    8200
    8201
  ];
}
