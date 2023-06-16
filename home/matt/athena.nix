{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    ./global
    ./global/darwin.nix
  ];

  home.packages = with pkgs; [
    gh
    google-cloud-sdk
    ngrok
    teams
    teleport
    zoom-us
  ];

  home.shellAliases = {
    db-stage = "tsh -k no db login --db-user=teleport-rw@slab-stage.iam --db-name=slab slab-sql-stage-pg14";
    db-prod-replica = "tsh -k no db login --db-user=teleport-ro@slab-prod.iam --db-name=slab slab-sql-prod-replica-pg14-0";
    slab-restart = "npm run docker:down && npm run docker:up";
    slab-up = "npm run docker:up";
    slab-ssh = "npm run docker:ssh";
  };

  programs.nushell.shellAliases = {
    db-stage = "tsh -k no db login --db-user=teleport-rw@slab-stage.iam --db-name=slab slab-sql-stage-pg14";
    db-prod-replica = "tsh -k no db login --db-user=teleport-ro@slab-prod.iam --db-name=slab slab-sql-prod-replica-pg14-0";
    slab-restart = "nu -c 'npm run docker:down; npm run docker:up'";
    slab-up = "npm run docker:up";
    slab-ssh = "npm run docker:ssh";
  };

  home.dock = {
    enable = true;
    entries = [
      {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
      {path = "${pkgs.firefox-bin}/Applications/Firefox.app/";}
      {path = "/System/Applications/Messages.app/";}
      {path = "/System/Applications/Mail.app/";}
      {path = "${pkgs.zoom-us}/Applications/zoom.us.app/";}
      {path = "${pkgs.slack}/Applications/Slack.app/";}
      {path = "/Applications/Fantastical.app/";}
      {path = "/Applications/1Password.app/";}
      {path = "/Applications/Slab.app/";}
      {path = "/Applications/GitHub Desktop.app/";}
      {path = "${pkgs.kitty}/Applications/kitty.app/";}
      {path = "/Applications/Dash.app/";}
      {path = "/Applications/Postico 2.app/";}
      {path = "${pkgs.discord}/Applications/Discord.app/";}
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };

  programs.git.userEmail = "matt@slab.com";

  programs.mr = {
    settings = {
      "Projects/slab" = {
        checkout = "git clone https://github.com/slab/slab.git";
      };
      "Projects/scripts" = {
        checkout = "git clone https://github.com/slab/scripts.git";
      };
      "Projects/delta-elixir" = {
        checkout = "git clone https://github.com/slab/delta-elixir.git";
      };
      "Projects/nix-config" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/nix-config.git";
      };
    };
  };

  xdg.configFile."k9s/skin.yml".source = inputs.catppuccin-k9s + "/dist/mocha.yml";

  programs.kitty.darwinLaunchOptions = let
    slabSession = pkgs.writeText "kitty-session-slab" ''
      # first tab: slab work
      new_tab slab
      layout tall:bias=60;full_size=1
      cd ~/Projects/slab
      launch zsh -l -i -c nvim
      launch
      launch

      # second tab: nix-config
      new_tab nix-config
      layout tall:bias=60;full_size=1
      cd ~/Projects/nix-config
      launch zsh -l -i -c nvim
      launch
    '';
  in ["--session" "${slabSession}"];

  # this doesn't work
  # home.file.".ngrok2/ngrok.yml".source = config.age.secrets."ngrok.yml".path;

  home.activation.write-ngrok-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # need to be able to use getconf
    export PATH=$PATH:/usr/bin
    mkdir -p ${config.home.homeDirectory}/.ngrok2
    ln -sf ${config.age.secrets."ngrok.yml".path} ${config.home.homeDirectory}/.ngrok2/ngrok.yml
  '';

  age.secrets."ngrok.yml".file = ../../secrets/ngrok.age;
}
