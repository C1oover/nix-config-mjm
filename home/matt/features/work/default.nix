{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./git.nix
    ./helix.nix
    ./ngrok.nix
  ];

  home.packages = with pkgs; [
    google-cloud-sdk
    teleport

    (writeShellApplication {
      name = "db";
      runtimeInputs = [teleport];
      text = builtins.readFile ./db.sh;
    })
  ];

  home.shellAliases = {
    slab-restart = "npm run docker:down && npm run docker:up";
    slab-up = "npm run docker:up";
    slab-ssh = "npm run docker:ssh";
    piex = "slab-ssh bin/phx-iex";
  };

  xdg.configFile."k9s/skin.yml".source = inputs.catppuccin-k9s + "/dist/mocha.yml";

  programs.kitty.darwinLaunchOptions = ["--session" "${./kitty-session-slab}"];
}
