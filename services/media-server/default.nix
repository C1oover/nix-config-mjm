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
    ./mount.nix
    ./navidrome.nix
    ./peertube.nix
    ./sabnzbd.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.media-server = {
      vault = {
        enable = true;
      };
    };

    mjm.backups.media-server.repositoryName = "mediaserver";
  };
}
