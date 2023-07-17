{
  lib,
  pkgs,
  ...
}: {
  programs.sway = {
    enable = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_DBUS_REMOTE=1
      export NIXOS_OZONE_WL=1
    '';
    extraPackages = with pkgs; [swaylock swayidle xwayland qt5.qtwayland];
    wrapperFeatures.gtk = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "sway";
        user = "matt";
      };
    };
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  fonts = {
    fonts = with pkgs; [
      open-sans
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      font-awesome
    ];

    fontconfig = {
      defaultFonts = {
        monospace = ["PragmataPro Mono" "Noto Sans Mono"];
        sansSerif = ["Open Sans" "Noto Sans"];
        serif = ["Noto Serif"];
      };
    };
  };

  programs.light.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.udisks2.enable = true;

  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome3.gvfs;
  };
  programs.thunar.enable = true;
}
