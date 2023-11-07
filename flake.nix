{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:NixOS/nixos-hardware";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.home-manager.follows = "home-manager";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    helix.url = "github:helix-editor/helix";
    nix-colors.url = "github:misterio77/nix-colors";
    jujutsu.url = "github:martinvonz/jj";
    nix-fast-build.url = "github:Mic92/nix-fast-build";
    attic.url = "github:zhaofengli/attic";

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-zsh = {
      url = "github:catppuccin/zsh-syntax-highlighting";
      flake = false;
    };
    catppuccin-k9s = {
      url = "github:catppuccin/k9s";
      flake = false;
    };
    catppuccin-newsboat = {
      url = "github:catppuccin/newsboat";
      flake = false;
    };
    catppuccin-i3 = {
      url = "github:catppuccin/i3";
      flake = false;
    };
    catppuccin-rofi = {
      url = "github:catppuccin/rofi";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        ./hosts
        ./modules
        ./packages
        ./terraform
      ];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {
        system,
        pkgs,
        lib,
        ...
      }: {
        _module.args.pkgs = let
          source =
            if system == "x86_64-linux" || system == "aarch64-linux"
            then inputs.nixos
            else inputs.nixpkgs;
        in
          import source {
            inherit system;
            # terraform is now under an unfree license
            config.allowUnfree = true;
          };

        devenv.shells.default = {
          pre-commit = {
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
            };

            excludes = [
              "home/matt/features/firefox/addons/addons.nix"
            ];
          };
          dotenv.disableHint = true;
        };

        formatter = pkgs.alejandra;

        apps.ci-flake-update.program = lib.getExe (pkgs.writeShellApplication {
          name = "ci-flake-update";
          runtimeInputs = with pkgs; [curl jq nix git];
          text = builtins.readFile ./flake-update.sh;
        });
      };
    };
}
