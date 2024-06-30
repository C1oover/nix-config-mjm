{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.media-server;
in
{
  options.mjm.media-server = {
    enable = mkEnableOption "media server";
  };

  imports = [
    ./arr.nix
    ./invidious.nix
    ./jellyfin.nix
    ./navidrome.nix
    ./peertube.nix
    ./sabnzbd.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.media-server = {
      vault = {
        enable = true;
        keys.backup_password = { };
      };
    };

    mjm.backups.mediaserver = {
      repositoryName = "mediaserver";
      passwordFile = config.mjm.services.media-server.vault.keys.backup_password.path;
    };
  };
}
