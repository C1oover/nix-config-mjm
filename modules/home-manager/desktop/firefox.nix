{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
  cfg = config.cloover.desktop;
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      cloover.firefox.enable = mkDefault true;
    }
    (mkIf pkgs.stdenv.isLinux {
      programs.firefox.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
    })
  ]);
}
