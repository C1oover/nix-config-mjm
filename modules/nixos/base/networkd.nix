{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.cloover.networkd;
in
{
  options.cloover.networkd = {
    enable = mkOption {
      type = types.bool;
      default = !config.networking.networkmanager.enable;
    };

    primaryIface = mkOption {
      type = types.str;
    };

    primaryLinkName = mkOption {
      type = types.str;
      default = "lan0";
    };

    secondaryLinkName = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    bridgeParentName = mkOption {
      type = types.str;
      default = if cfg.secondaryLinkName == null then cfg.primaryLinkName else cfg.secondaryLinkName;
      readOnly = true;
    };

    macvlan.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    networking.useDHCP = false;

    cloover.networkd.primaryIface =
      if cfg.secondaryLinkName != null then
        cfg.primaryLinkName
      else if cfg.macvlan.enable then
        "mac0"
      else
        cfg.primaryLinkName;

    systemd.network = {
      enable = true;

      networks."10-primary-lan" = {
        name = cfg.primaryIface;
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

      # if using macvlan without a secondary link, we need to create a macvlan device
      # to use as the primary interface, otherwise communication with other devices on
      # the macvlan bridge will not be able to communicate with the host.
      netdevs.mac0 = mkIf (cfg.primaryIface != cfg.primaryLinkName) {
        netdevConfig = {
          Name = cfg.primaryIface;
          Kind = "macvlan";
        };
        macvlanConfig.Mode = "bridge";
      };

      networks."10-bridge-lan" = mkIf cfg.macvlan.enable {
        name = cfg.bridgeParentName;
        networkConfig = {
          MACVLAN = mkIf (cfg.primaryIface != cfg.primaryLinkName) cfg.primaryIface;
          IPv6AcceptRA = false;
          LinkLocalAddressing = false;
        };
      };

      links = {
        "10-virtio" = {
          matchConfig.Driver = "virtio_net";
          linkConfig.Name = "lan0";
        };
        "10-rpi" = {
          matchConfig.Driver = "bcmgenet";
          linkConfig.Name = "lan0";
        };
        "10-vm-bridge" = {
          matchConfig.Property = "ID_VENDOR_ID=0x10ec ID_MODEL_ID=0x8125";
          linkConfig.Name = "lan1";
        };
        "15-other-ethernet" = {
          matchConfig.Driver = "e1000e r8169";
          linkConfig.Name = "lan0";
        };
      };
    };
  };
}
