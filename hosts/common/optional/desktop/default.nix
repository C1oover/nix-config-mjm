{
  pkgs,
  outputs,
  config,
  ...
}:
{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      public-sans
      open-sans
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      font-awesome
      cascadia-code
      ibm-plex
      iosevka
      agave
      outputs.packages.${pkgs.system}.pragmata-pro
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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.kdeconnect.enable = true;

  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
