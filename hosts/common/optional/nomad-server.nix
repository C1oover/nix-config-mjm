{ pkgs, ... }:

{
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
    };

    # don't need docker on the servers, only clients
    enableDocker = false;
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
