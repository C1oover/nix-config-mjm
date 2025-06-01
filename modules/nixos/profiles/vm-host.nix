{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.cloover.profiles.vm-host;
in
{
  options.cloover.profiles.vm-host = {
    enable = mkEnableOption "profile for a host running VMs";
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

    cloover.consul.enable = true;
    cloover.libvirtd.enable = true;
    cloover.networkd.secondaryLinkName = "lan1";
    cloover.remote-builder.enable = true;
    cloover.server.enable = true;
    cloover.spire.agent.enable = true;

    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
    boot.zfs.extraPools = [ "slow" ];
    services.zfs.autoScrub.enable = true;

    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
