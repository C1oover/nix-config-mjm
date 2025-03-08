{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.libvirtd;
in
{
  imports = [ ./backups.nix ];

  options.mjm.libvirtd = {
    enable = mkEnableOption "libvirtd";
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

    # TODO do network device config here instead of relying on it from proxmox module.

    users.users.${config.mjm.username}.extraGroups = [ "libvirtd" ];

    # TODO parameterize if I ever have uneven hosts
    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
    hardware.ksm.enable = true;
  };
}
