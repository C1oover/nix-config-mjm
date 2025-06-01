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
    ;
  cfg = config.cloover.libvirtd;
in
{
  imports = [ ./backups.nix ];

  options.cloover.libvirtd = {
    enable = mkEnableOption "libvirtd";
  };

  config = mkIf cfg.enable {
    # really don't want an entire VM host rebooting automatically
    deployment.rebootAutomatically = false;

    environment.systemPackages = [ pkgs.virtiofsd ];

    virtualisation.libvirtd = {
      enable = true;
      package = pkgs.libvirt;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
      onBoot = "ignore"; # VMs should be configured to autostart
      onShutdown = "shutdown";
      parallelShutdown = 3;
    };

    services.lldpd.enable = true;

    users.users.${config.cloover.username}.extraGroups = [ "libvirtd" ];

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
