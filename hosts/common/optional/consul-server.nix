{
  services.consul = {
    enable = true;
    webUi = true;

    interface.advertise = "ens18";

    extraConfig = {
      server = true;
      bootstrap_expect = 3;
      # TODO retry_join
      client_addr = "0.0.0.0";
      ports.grpc = 8502;
      connect.enabled = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    8301
    8302
    8500
    8502
    8503
    8600
  ];
}
