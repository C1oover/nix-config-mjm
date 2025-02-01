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
    fonts = {
      packages = with pkgs; [
        public-sans
        open-sans
        noto-fonts-emoji
        nerd-fonts.agave
        font-awesome
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [
            "PragmataPro Mono"
            "Noto Sans Mono"
          ];
          sansSerif = [ "Noto Sans" ];
          serif = [ "Noto Serif" ];
        };
      };
    };
  };
}
