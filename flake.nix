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
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    catppuccin.url = "github:catppuccin/starship";
    catppuccin.flake = false;
    catppuccin-zsh.url = "github:catppuccin/zsh-syntax-highlighting";
    catppuccin-zsh.flake = false;
    catppuccin-k9s.url = "github:catppuccin/k9s";
    catppuccin-k9s.flake = false;
    astronvim.url = "github:AstroNvim/AstroNvim/nightly";
    astronvim.flake = false;
  };

  outputs =
    { self
    , darwin
    , nixpkgs
    , flake-utils
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      mkDarwin = arch: modules:
        darwin.lib.darwinSystem {
          inherit modules;

          system = "${arch}-darwin";
          inputs = { inherit darwin nixpkgs; };
          specialArgs = { inherit inputs outputs; };
        };
      mkNixos = modules:
        nixpkgs.lib.nixosSystem {
          inherit modules;
          specialArgs = { inherit inputs outputs; };
        };
    in
    {
      homeManagerModules = import ./modules/home-manager;
      darwinModules = import ./modules/darwin;
      nixosModules = import ./modules/nixos;

      darwinConfigurations = {
        mars = mkDarwin "x86_64" [ ./hosts/mars ];
        athena = mkDarwin "aarch64" [ ./hosts/athena ];
      };

      nixosConfigurations = {
        megaera = mkNixos [ ./hosts/megaera ];
        tisiphone = mkNixos [ ./hosts/tisiphone ];
        alecto = mkNixos [ ./hosts/alecto ];

        arges = mkNixos [ ./hosts/arges ];
        brontes = mkNixos [ ./hosts/brontes ];
        steropes = mkNixos [ ./hosts/steropes ];

        hypnos = mkNixos [ ./hosts/hypnos ];
        helios = mkNixos [ ./hosts/helios ];

        orion = mkNixos [ ./hosts/orion ];
        nemesis = mkNixos [ ./hosts/nemesis ];
        aion = mkNixos [ ./hosts/aion ];
        gaia = mkNixos [ ./hosts/gaia ];
      };

      formatter = flake-utils.lib.eachDefaultSystemMap (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
