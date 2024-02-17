{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/garage

    ./services/jellyfin.nix
    ./services/sabnzbd.nix
    ./services/arr.nix
    ./services/mediaserver-backup.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (
        old: { configureFlags = builtins.filter (f: f != "--enable-libaribcaption") old.configureFlags; }
      );
    })
  ];

  networking.hostName = "chaos";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  vault-secrets.roleId = "a87469f6-a653-37ab-8aa4-2a1adeed567f";
  vault-secrets.secretIdFile = config.age.secrets."approle-secret-id".path;

  age.secrets."approle-secret-id".file = ../../secrets/chaos-approle-secret-id.age;

  system.stateVersion = "22.11";
}
