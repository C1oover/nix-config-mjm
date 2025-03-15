{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.profiles.vm-host;
in
{
  options.mjm.profiles.vm-host = {
    enable = mkEnableOption "profile for a host running VMs";
    managementInterface = mkOption {
      type = types.str;
    };
    bridgeInterface = mkOption {
      type = types.str;
    };
    iscsiName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    fileSystems."/" = {
      device = "rpool/nixos/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    fileSystems."/nix" = {
      device = "rpool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    fileSystems."/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    mjm.consul.enable = true;
    mjm.libvirtd = {
      enable = true;
      inherit (cfg) managementInterface bridgeInterface;
    };
    mjm.remote-builder.enable = true;
    mjm.server.enable = true;

    services.openiscsi = {
      enable = true;
      name = cfg.iscsiName;
    };

    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
    boot.zfs.extraPools = [ "slow" ];
    services.zfs.autoScrub.enable = true;
  };
}
