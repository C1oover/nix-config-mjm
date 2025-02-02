{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable {
    boot.consoleLogLevel = 3;
    boot.plymouth.enable = true;
    boot.kernelParams = [ "quiet" ];
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
    };
    catppuccin.plymouth.enable = true;
    catppuccin.tty.enable = true;
  };
}
