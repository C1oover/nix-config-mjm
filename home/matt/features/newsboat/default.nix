{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.shellAliases.nb = "${pkgs.newsboat}/bin/newsboat";

  programs.newsboat = {
    enable = true;
    autoReload = true;
    browser =
      if pkgs.stdenv.isLinux then
        ''"xdg-open %u"''
      else
        ''"/usr/bin/open -a ${config.programs.firefox.package}/Applications/Firefox.app -u %u"'';
    extraConfig = ''
      text-width 100
      urls-source "miniflux"
      miniflux-url "https://feeds.midna.dev/"
      miniflux-tokenfile ${config.home.homeDirectory}/.config/newsboat/miniflux-token
    '';
  };

  # use this instead of an activation script because, on boot, the home-manager service
  # does not have the $XDG_RUNTIME_DIR variable defined.
  systemd.user.services.miniflux-token = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "link miniflux-token secret";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "link-miniflux-token";
          text = ''
            mkdir -p ${config.home.homeDirectory}/.config/newsboat
            ln -sf "${
              config.age.secrets."miniflux-token".path
            }" ${config.home.homeDirectory}/.config/newsboat/miniflux-token
          '';
        }
      );
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.link-miniflux-token = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # need to be able to use getconf
      export PATH=$PATH:/usr/bin
      mkdir -p ${config.home.homeDirectory}/.config/newsboat
      ln -sf ${
        config.age.secrets."miniflux-token".path
      } ${config.home.homeDirectory}/.config/newsboat/miniflux-token
    ''
  );

  age.secrets."miniflux-token".file = ../../../../secrets/newsboat-miniflux-token.age;
}
