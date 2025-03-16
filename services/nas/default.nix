{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.nas;
in
{
  options.mjm.nas = {
    enable = mkEnableOption "NAS";
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = config.networking.hostName;
          "netbios name" = config.networking.hostName;
          security = "user";
          "guest account" = "nobody";
          "create mask" = "0666";
          "directory mask" = "0777";
        };
        media = {
          path = "/mnt/slow/media";
          browseable = "yes";
          writable = "yes";
          "read only" = "no";
          "guest ok" = "no";
        };
      };
    };

    boot.kernelParams = [ "zfs.zfs_arc_max=${toString (8 * 1024 * 1024 * 1024)}" ];
    boot.zfs.extraPools = [
      "fast"
      "slow"
    ];
    services.zfs.autoScrub.enable = true;

    users.users.mediaserver = {
      isSystemUser = true;
      group = "mediaserver";
      createHome = false;
    };
    users.groups.mediaserver = { };
  };
}
