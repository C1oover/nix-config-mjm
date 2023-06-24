{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hardware.url = "github:NixOS/nixos-hardware";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "darwin";
    agenix.inputs.home-manager.follows = "home-manager";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    nixvim.url = "github:pta2002/nixvim";

    catppuccin.url = "github:catppuccin/starship";
    catppuccin.flake = false;
    catppuccin-zsh.url = "github:catppuccin/zsh-syntax-highlighting";
    catppuccin-zsh.flake = false;
    catppuccin-k9s.url = "github:catppuccin/k9s";
    catppuccin-k9s.flake = false;
    catppuccin-newsboat.url = "github:catppuccin/newsboat";
    catppuccin-newsboat.flake = false;
    astronvim.url = "github:AstroNvim/AstroNvim/nightly";
    astronvim.flake = false;
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        ./hosts
        ./modules
      ];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {
        pkgs,
        config,
        ...
      }: {
        # need to run `nix develop .#pre-commit` after changing these
        pre-commit.settings = {
          hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
          };

          excludes = [
            "home/matt/features/firefox/addons/addons.nix"
          ];
        };

        formatter = pkgs.alejandra;
        devShells.pre-commit = config.pre-commit.devShell;
        packages.pre-commit = config.pre-commit.settings.run;
      };
    };
}
