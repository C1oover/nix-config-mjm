{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    pragmata-pro
    cascadia-code
    ibm-plex
    agave
    (input-fonts.override { acceptLicense = true; })
    departure-mono
    noto-fonts
  ];
}
