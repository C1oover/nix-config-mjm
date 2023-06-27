{config, ...}: {
  programs.nushell = {
    enable = true;
    extraConfig = ''
      let-env PATH = ($env.PATH | split row (char esep) |
        prepend '/usr/local/bin' |
        prepend '/opt/homebrew/bin' |
        prepend '/nix/var/nix/profiles/default/bin' |
        prepend '/run/current-system/sw/bin' |
        prepend '/etc/profiles/per-user/${config.home.username}/bin' |
        prepend '${config.home.homeDirectory}/.nix-profile/bin')

      let-env config = {
        show_banner: false,
        shell_integration: true,
      }
    '';

    environmentVariables = {
      EDITOR = "nvim";
      NIX_USER_PROFILE_DIR = "/nix/var/nix/profiles/per-user/${config.home.username}";
      NIX_PROFILES = "\"/nix/var/nix/profiles/default /run/current-system/sw /etc/profiles/per-user/${config.home.username} ${config.home.homeDirectory}/.nix-profile\"";
      NIX_REMOTE = "daemon";
    };
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };
}
