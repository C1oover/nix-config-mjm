{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./gc.nix
    ./node-exporter.nix
  ];

  options.cloover.server = {
    enable = mkEnableOption "server setup";
  };
}
