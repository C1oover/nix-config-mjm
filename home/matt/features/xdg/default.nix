{
  lib,
  pkgs,
  ...
}: {
  xdg = {
    enable = true;
    userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
    };
  };
}
