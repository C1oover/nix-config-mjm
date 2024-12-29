{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./gc.nix
    ./node-exporter.nix
  ];

  options.mjm.server = {
    enable = mkEnableOption "server setup";
  };
}
