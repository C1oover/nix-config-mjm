{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.networkd;
in
{
  options.mjm.networkd = {
    enable = mkOption {
      type = types.bool;
      default = !config.networking.networkmanager.enable;
    };

    primaryLinkName = mkOption {
      type = types.str;
      default = "ens* end* enp*";
    };

    secondaryLinkName = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    bridge.enable = mkOption {
      type = types.bool;
      default = cfg.secondaryLinkName != null;
    };
  };

  config = mkIf cfg.enable {
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      networks."10-bridge-lan" = mkIf cfg.bridge.enable {
        name = if cfg.secondaryLinkName == null then cfg.primaryLinkName else cfg.secondaryLinkName;
        networkConfig.Bridge = "vmbr0";
      };

      networks."10-primary-lan" = {
        name = if cfg.secondaryLinkName == null && cfg.bridge.enable then "vmbr0" else cfg.primaryLinkName;
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

      networks."10-secondary-lan" = mkIf (cfg.secondaryLinkName != null && cfg.bridge.enable) {
        name = "vmbr0";
      };

      netdevs.vmbr0 = mkIf cfg.bridge.enable {
        netdevConfig = {
          Name = "vmbr0";
          Kind = "bridge";
        };
      };
    };
  };
}
