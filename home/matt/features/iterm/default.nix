{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.iterm2];

  xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = ./com.googlecode.iterm2.plist;

  targets.darwin.defaults = {
    "com.googlecode.iterm2" = {
      PrefsCustomFolder = "${config.home.homeDirectory}/.config/iterm2";
    };
  };
}
