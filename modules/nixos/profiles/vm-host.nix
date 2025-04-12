{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.mjm.profiles.vm-host;
in
{
  options.mjm.profiles.vm-host = {
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

    mjm.consul.enable = true;
    mjm.libvirtd.enable = true;
    mjm.networkd.secondaryLinkName = "lan1";
    mjm.remote-builder.enable = true;
    mjm.server.enable = true;
    mjm.spire.agent.enable = true;

    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
    boot.zfs.extraPools = [ "slow" ];
    services.zfs.autoScrub.enable = true;
  };
}
