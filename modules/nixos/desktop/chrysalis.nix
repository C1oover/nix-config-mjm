{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.chrysalis ];
    services.udev.packages = [ pkgs.chrysalis ];
  };
}
