{ config, lib, ... }:
let
  useNetworkd = !config.networking.networkmanager.enable;
in
{
  networking.useDHCP = lib.mkIf useNetworkd false;
  systemd.network = lib.mkIf useNetworkd {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = lib.mkDefault "ens* end* enp0s6";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
      };
      dhcpV4Config = {
        UseDomains = true;
      };
      dhcpV6Config = {
        UseDNS = false;
      };
    };
  };
}
