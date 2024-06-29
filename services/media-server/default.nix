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
    mjm.services.media-server = { };
    mjm.backups.mediaserver = {
      repositoryName = "mediaserver";
      passwordFile = config.vault-secrets.services.media-server.keys.backup_password.path;
    };

    vault.services.media-server = { };
    vault-secrets.services.media-server.keys.backup_password = { };
  };
}
