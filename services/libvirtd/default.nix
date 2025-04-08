{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkMerge
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.libvirtd;
in
{
  imports = [ ./backups.nix ];

  options.mjm.libvirtd = {
    enable = mkEnableOption "libvirtd";

    managementInterface = mkOption {
      type = types.str;
      default = cfg.bridgeInterface;
    };

    bridgeInterface = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    # really don't want an entire VM host rebooting automatically
    deployment.rebootAutomatically = false;

    environment.systemPackages = [ pkgs.virtiofsd ];

    virtualisation.libvirtd = {
      enable = true;
      package = pkgs.libvirt.override { enableIscsi = true; };
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
      onBoot = "ignore"; # VMs should be configured to autostart
      onShutdown = "shutdown";
      parallelShutdown = 3;
    };

    systemd.network.networks = mkMerge [
      {
        "10-lan2" = {
          matchConfig.Name = cfg.bridgeInterface;
          networkConfig.Bridge = "vmbr0";
        };
      }
      (mkIf (cfg.managementInterface == cfg.bridgeInterface) {
        "10-lan" = {
          matchConfig.Name = "vmbr0";
          linkConfig.RequiredForOnline = "routable";
        };
      })
      (mkIf (cfg.managementInterface != cfg.bridgeInterface) {
        # other config for this network is in base module
        "10-lan".matchConfig.Name = cfg.managementInterface;
        "10-lan2-bridge".matchConfig.Name = "vmbr0";
      })
    ];

    systemd.network.netdevs.vmbr0 = {
      netdevConfig = {
        Name = "vmbr0";
        Kind = "bridge";
      };
    };

    services.lldpd.enable = true;

    users.users.${config.mjm.username}.extraGroups = [ "libvirtd" ];

    hardware.ksm.enable = true;

    # this doesn't agree with zfs arc it seems
    systemd.services.disable-mglru = {
      wantedBy = [ "basic.target" ];
      script = ''
        ${pkgs.coreutils-full}/bin/echo n > /sys/kernel/mm/lru_gen/enabled
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      unitConfig = {
        ConditionPathExists = "/sys/kernel/mm/lru_gen/enabled";
        Description = "Disable Multi-Gen LRU";
      };
    };
  };
}
