{ pkgs, ... }:
let
  inherit (import ../../../../packages { inherit pkgs; }) pragmata-pro;
in
{
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    pragmata-pro
    cascadia-code
    ibm-plex
    iosevka
    agave
    (input-fonts.override { acceptLicense = true; })
  ];
}
