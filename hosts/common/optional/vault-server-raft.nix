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
      retry_join {
        leader_api_addr = "http://10.0.2.40:8200"
      }
      retry_join {
        leader_api_addr = "http://10.0.2.42:8200"
      }
      retry_join {
        leader_api_addr = "http://10.0.2.43:8200"
      }
    '';
    listenerExtraConfig = ''
      cluster_address = "0.0.0.0:8201"
      telemetry {
        unauthenticated_metrics_access = true
      }
    '';
    extraConfig = ''
      api_addr = "http://{{ GetInterfaceIP \"ens18\" }}:8200"
      cluster_addr = "https://{{ GetInterfaceIP \"ens18\" }}:8201"
      disable_mlock = true
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
