{pkgs, ...}: {
  imports = [
    ./hyprland.nix
    ./sway.nix
  ];

  home.packages = with pkgs; [
    libsForQt5.kmahjongg
    xdg-utils
    grim
    slurp
    imv
    pavucontrol
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

  programs.mpv = {
    enable = true;
  };

  services.kdeconnect.enable = true;
}
