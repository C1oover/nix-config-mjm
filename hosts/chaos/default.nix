{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ./services/jellyfin.nix
    ./services/sabnzbd.nix
    ./services/arr.nix
    ./services/invidious.nix
    ./services/mediaserver-backup.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (old: {
        configureFlags = builtins.filter (f: f != "--enable-libaribcaption") old.configureFlags;
      });
    })
  ];

  networking.hostName = "chaos";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  mjm.consul-agent.enable = true;
  mjm.garage.enable = true;
  mjm.postgresql.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "a87469f6-a653-37ab-8aa4-2a1adeed567f";

  system.stateVersion = "22.11";
}
