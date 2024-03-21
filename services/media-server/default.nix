{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.mjm.media-server = {
    enable = mkEnableOption "media server";
  };

  imports = [
    ./arr.nix
    ./backup.nix
    ./invidious.nix
    ./jellyfin.nix
    ./sabnzbd.nix
  ];
}
