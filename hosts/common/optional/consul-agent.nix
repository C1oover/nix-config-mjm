{lib, ...}: {
  services.consul = {
    enable = true;
    webUi = true;

    extraConfig = {
      retry_join = lib.mkDefault ["10.0.2.40" "10.0.2.42" "10.0.2.43"];

      client_addr = "0.0.0.0";
      bind_addr = "[::]";
      advertise_addr_ipv4 = "{{ GetDefaultInterfaces | include \"type\" \"ipv4\" | attr \"address\" }}";
      advertise_addr_ipv6 = "{{ GetDefaultInterfaces | include \"type\" \"ipv6\" | exclude \"RFC\" \"6890\" | attr \"address\" }}";

      ports.grpc = 8502;
      connect.enabled = true;
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
    8600
  ];
}
