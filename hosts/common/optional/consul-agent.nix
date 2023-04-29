{ lib, ... }: {
  services.consul = {
    enable = true;
    webUi = true;

    extraConfig = {
      retry_join = lib.mkDefault [ "10.0.2.40" "10.0.2.42" "10.0.2.43" ];
      client_addr = "0.0.0.0";
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
}
