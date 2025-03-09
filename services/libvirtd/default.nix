{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
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
      default = config.mjm.proxmox.managementInterface;
    };

    bridgeInterface = mkOption {
      type = types.str;
      default = config.mjm.proxmox.bridgeInterface;
    };
  };

  config = mkIf cfg.enable {
    # really don't want an entire VM host rebooting automatically
    deployment.rebootAutomatically = false;

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

    systemd.network.networks = {
      "10-lan" = {
        matchConfig.Name = cfg.managementInterface;
        # other config for this network is in base module
      };
      "10-lan2" = {
        matchConfig.Name = cfg.bridgeInterface;
        networkConfig.Bridge = "vmbr0";
      };
      "10-lan2-bridge" = {
        matchConfig.Name = "vmbr0";
      };
    };

    systemd.network.netdevs.vmbr0 = {
      netdevConfig = {
        Name = "vmbr0";
        Kind = "bridge";
      };
    };

    users.users.${config.mjm.username}.extraGroups = [ "libvirtd" ];

    # TODO parameterize if I ever have uneven hosts
    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
    hardware.ksm.enable = true;
  };
}
