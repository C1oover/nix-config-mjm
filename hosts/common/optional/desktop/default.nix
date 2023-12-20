{
  pkgs,
  inputs,
  outputs,
  config,
  ...
}: {
  imports = [
    inputs.kde2nix.nixosModules.plasma6
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
  };

  # this is needed for now because the gnupg module doesn't know about plasma6
  programs.gnupg.agent.pinentryFlavor = "qt";

  # move fprintd after unix auth so that it's possible to unlock
  # by either entering a password or with fingerprint
  security.pam.services.polkit-1.rules.auth.fprintd.order = config.security.pam.services.polkit-1.rules.auth.unix.order + 5;
  security.pam.services.login.rules.auth.fprintd.order = config.security.pam.services.login.rules.auth.unix.order + 5;
  security.pam.services.kde.rules.auth.fprintd.order = config.security.pam.services.kde.rules.auth.unix.order + 5;

  fonts = {
    packages = with pkgs; [
      public-sans
      open-sans
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      font-awesome
      cascadia-code
      ibm-plex
      iosevka
      agave
      outputs.packages.${pkgs.system}.pragmata-pro
    ];

    fontconfig = {
      defaultFonts = {
        monospace = ["PragmataPro Mono" "Noto Sans Mono"];
        sansSerif = ["Public Sans" "Open Sans" "Noto Sans"];
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

  programs.kdeconnect.enable = true;
}
