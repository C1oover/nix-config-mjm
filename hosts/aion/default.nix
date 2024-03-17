{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ./services/haproxy.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking.hostName = "aion";
  networking.domain = "midna.dev";

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-lan".enable = false;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "ipv4";
      address = [ "2a01:4ff:1f0:879b::1/64" ];
      routes = [ { routeConfig.Gateway = "fe80::1"; } ];
    };
  };

  mjm.server = {
    enable = true;
    enablePromtail = false;
    enableNodeExporter = false;
  };

  system.stateVersion = "23.11";
}
