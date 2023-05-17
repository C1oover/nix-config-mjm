{
  services.consul = {
    enable = true;
    webUi = true;

    interface.advertise = "ens18";

    extraConfig = {
      server = true;
      bootstrap_expect = 3;
      retry_join = ["10.0.2.40" "10.0.2.42" "10.0.2.43"];
      client_addr = "0.0.0.0";
      ports.grpc = 8502;
      connect.enabled = true;
      telemetry = {
        prometheus_retention_time = "1h";
        disable_hostname = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8300
    8301
    8302
    8500
    8502
    8503
    8600
  ];

  networking.firewall.allowedUDPPorts = [
    8301
    8302
    8600
  ];
}
