{pkgs, ...}: {
  imports = [
    ./sway.nix
  ];

  home.packages = with pkgs; [
    xdg-utils
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

  programs.mpv = {
    enable = true;
  };
}
