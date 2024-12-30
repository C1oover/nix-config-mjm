{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      mjm.firefox.enable = mkDefault true;
    }
    (mkIf pkgs.stdenv.isLinux {
      programs.firefox.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
    })
    (mkIf pkgs.stdenv.isDarwin {
      mjm.firefox.package = pkgs.firefox-bin;
    })
  ]);
}
