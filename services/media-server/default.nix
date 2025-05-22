{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.mjm.media-server = {
    enable = mkEnableOption "media server";
  };

  imports = [
    ./invidious.nix
    ./mount.nix
    ./peertube.nix
  ];
}
