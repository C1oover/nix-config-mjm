{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.networkd;

  hasBridge = cfg.bridge.enable || cfg.macvlan.enable;
  bridgeName =
    if cfg.bridge.enable then
      "vmbr0"
    else if cfg.macvlan.enable then
      "mac0"
    else
      builtins.throw "trying to use bridge name when no bridging virtual device is enabled";
  bridgeParentName =
    if cfg.secondaryLinkName == null then cfg.primaryLinkName else cfg.secondaryLinkName;
in
{
  options.mjm.networkd = {
    enable = mkOption {
      type = types.bool;
      default = !config.networking.networkmanager.enable;
    };

    primaryLinkName = mkOption {
      type = types.str;
      default = "lan0";
    };

    secondaryLinkName = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    bridge.enable = mkOption {
      type = types.bool;
      default = cfg.secondaryLinkName != null;
    };

    macvlan.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      networks."10-bridge-lan" = mkIf hasBridge {
        name = bridgeParentName;
        networkConfig.Bridge = mkIf cfg.bridge.enable "vmbr0";
        networkConfig.MACVLAN = mkIf cfg.macvlan.enable "mac0";
      };

      networks."10-primary-lan" = {
        name = if cfg.secondaryLinkName == null && hasBridge then bridgeName else cfg.primaryLinkName;
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

      networks."10-secondary-lan" = mkIf (cfg.secondaryLinkName != null && hasBridge) {
        name = bridgeName;
      };

      netdevs.vmbr0 = mkIf cfg.bridge.enable {
        netdevConfig = {
          Name = "vmbr0";
          Kind = "bridge";
        };
      };

      netdevs.mac0 = mkIf cfg.macvlan.enable {
        netdevConfig = {
          Name = "mac0";
          Kind = "macvlan";
        };
        macvlanConfig.Mode = "bridge";
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
