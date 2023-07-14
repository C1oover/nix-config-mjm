{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./global
    ./global/darwin.nix

    ./features/homelab
  ];

  home.dock = {
    enable = true;
    entries = [
      {path = "/System/Applications/Mail.app/";}
      {path = "${pkgs.firefox-bin}/Applications/Firefox.app/";}
      {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
      {path = "/Applications/Beeper.app/";}
      {path = "/System/Applications/Maps.app/";}
      {path = "/Applications/Fantastical.app/";}
      {path = "/System/Applications/System Settings.app/";}
      {path = "/Applications/1Password.app/";}
      {path = "/Applications/Drafts.app/";}
      {path = "${pkgs.kitty}/Applications/kitty.app/";}
      {path = "/Applications/Dash.app/";}
      {path = "/Applications/Slab.app/";}
      {path = "${pkgs.discord}/Applications/Discord.app/";}
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "nas" = {
        host = "nas";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.kitty.settings = {
    hide_window_decorations = "titlebar-only";
    focus_follows_mouse = "yes";
  };

  programs.mr = {
    settings = {
      "Projects/bastille-templates" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/bastille-templates.git";
      };
      "Projects/dark_vader" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/dark-vader.git";
      };
      "Projects/homelab" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/homelab.git";
      };
      "Projects/homelab-infra" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/homelab-infra.git";
      };
      "Projects/nix-config" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/nix-config.git";
      };
    };
  };
}
