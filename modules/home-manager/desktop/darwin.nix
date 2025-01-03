{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [ pkgs.dockutil ];
  };
}
