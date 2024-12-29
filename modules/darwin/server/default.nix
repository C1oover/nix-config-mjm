{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./node-exporter.nix
  ];

  options.mjm.server = {
    enable = mkEnableOption "server setup";
  };
}
