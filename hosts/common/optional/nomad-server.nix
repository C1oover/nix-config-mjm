{config, ...}: {
  services.nomad = {
    enable = true;
    settings = {
      server = {
        enabled = true;
        bootstrap_expect = 3;
      };
      vault = {
        enabled = true;
        address = "http://127.0.0.1:8200";
        create_from_role = "nomad-cluster";
      };
      telemetry = {
        collection_interval = "1s";
        disable_hostname = true;
        prometheus_metrics = true;
        publish_allocation_metrics = true;
        publish_node_metrics = true;
      };
    };
    credentials = {
      "nomad-vault-config.json" = config.age.secrets."nomad-vault-config.json".path;
    };

    # don't need docker on the servers, only clients
    enableDocker = false;
  };

  age.secrets."nomad-vault-config.json" = {
    file = ../../../secrets/${config.networking.hostName}-nomad-vault-config.age;
  };

  networking.firewall.allowedTCPPorts = [
    4646
    4647
    4648
  ];

  networking.firewall.allowedUDPPorts = [
    4648
  ];
}
