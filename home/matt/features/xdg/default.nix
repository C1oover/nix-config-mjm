{
  lib,
  pkgs,
  config,
  ...
}: {
  xdg = {
    enable = true;
    userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      createDirectories = true;

      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = null;
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = null;
      templates = null;
      videos = null;
    };
  };
}
