{
  pkgs,
  outputs,
  ...
}: {
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      outputs.packages.${pkgs.system}.pragmata-pro
      cascadia-code
      ibm-plex
      iosevka
      agave
    ];
  };
}
