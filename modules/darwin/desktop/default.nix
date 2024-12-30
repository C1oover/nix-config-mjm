{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.desktop;
in
{
  imports = [ ./homebrew.nix ];

  options.mjm.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.monaspace
      nerd-fonts.symbols-only
      pragmata-pro
      cascadia-code
      ibm-plex
      agave
      (input-fonts.override { acceptLicense = true; })
      departure-mono
      noto-fonts
      monaspace
    ];
  };
}
