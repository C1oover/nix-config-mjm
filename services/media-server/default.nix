{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.mjm.media-server = {
    enable = mkEnableOption "media server";
  };

  imports = [
    ./mount.nix
    ./peertube.nix
  ];
}
