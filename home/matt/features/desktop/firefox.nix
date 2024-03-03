{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable {
    mjm.firefox.enable = mkDefault true;
    programs.firefox.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
  };
}
