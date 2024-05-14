{ pkgs, config, ... }:
{
  imports = [
    ./git.nix
    ./helix.nix
    ./k9s.nix
  ];

  home.packages = builtins.attrValues {
    inherit (pkgs) cloudflared google-cloud-sdk teleport;
    db = pkgs.callPackage ./db.nix { };
  };

  home.shellAliases = {
    slab-restart = "npm run docker:down && slab-up && npm run docker:logs -- --no-log-prefix";
    slab-up = "docker compose up -d";
    slab-ssh = "npm run docker:ssh";
    piex = "slab-ssh bin/phx-iex";
  };
  programs.nushell.extraConfig = ''
    alias slab-ssh = npm run docker:ssh
    alias slab-up = docker compose up -d
    alias piex = slab-ssh bin/phx-iex

    def slab-restart [] {
      npm run docker:down
      slab-up
      npm run docker:logs -- --no-log-prefix
    }

    $env.ASDF_DIR = ($env.HOME | path join '.asdf')
    source ${config.home.homeDirectory}/.asdf/asdf.nu
  '';

  programs.kitty.darwinLaunchOptions = [
    "--session"
    "${./kitty-session-slab}"
  ];
}
