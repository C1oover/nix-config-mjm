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
}
