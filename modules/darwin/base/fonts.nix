{ pkgs, ... }:
{
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
}
