{pkgs, ...}: let
  # set brightness and volume for night
  nightMode = pkgs.writeShellApplication {
    name = "night-mode";
    runtimeInputs = with pkgs; [light pulseaudio];
    text = ''
      pactl set-sink-volume @DEFAULT_SINK@ 30%
      light -S 1
    '';
  };
in {
  imports = [
    ./hyprland.nix
    ./rofi.nix
    ./sway.nix
    ./waybar.nix
    ./wayland-common.nix
  ];

  home.packages = with pkgs; [
    libsForQt5.kmahjongg
    gnome.gnome-mahjongg
    xdg-utils
    grim
    slurp
    imv
    pavucontrol
    (catppuccin-kvantum.override {
      accent = "Mauve";
      variant = "Latte";
    })

    nightMode
  ];

  home.pointerCursor = {
    name = "Catppuccin-Latte-Light-Cursors";
    package = pkgs.catppuccin-cursors.latteLight;
    size = 48;
    x11 = {
      enable = true;
      defaultCursor = "Catppuccin-Latte-Light-Cursors";
    };
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Latte-Standard-Mauve-light";
      package = pkgs.catppuccin-gtk.override {
        accents = ["mauve"];
        variant = "latte";
      };
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.catppuccin-papirus-folders.override {
        accent = "mauve";
        flavor = "latte";
      };
    };
  };

  qt = {
    enable = true;
    platformTheme = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile."Kvantum/kvantum.config".text = ''
    theme=Catppuccin-Latte-Mauve
  '';

  programs.mpv = {
    enable = true;
  };

  services.kdeconnect.enable = true;
}
