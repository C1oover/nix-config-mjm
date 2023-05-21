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

    catppuccin.url = "github:catppuccin/starship";
    catppuccin.flake = false;
    catppuccin-zsh.url = "github:catppuccin/zsh-syntax-highlighting";
    catppuccin-zsh.flake = false;
    catppuccin-k9s.url = "github:catppuccin/k9s";
    catppuccin-k9s.flake = false;
    astronvim.url = "github:AstroNvim/AstroNvim/nightly";
    astronvim.flake = false;
  };

  outputs = {
    self,
    darwin,
    nixpkgs,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      let
        inherit (self) outputs;
        mkDarwin = arch: modules:
          darwin.lib.darwinSystem {
            inherit modules;

            system = "${arch}-darwin";
            inputs = {inherit darwin nixpkgs;};
            specialArgs = {inherit inputs outputs;};
          };
        mkNixos = modules:
          nixpkgs.lib.nixosSystem {
            inherit modules;
            specialArgs = {inherit inputs outputs;};
          };
      in {
        imports = [
          inputs.pre-commit-hooks-nix.flakeModule
        ];

        flake = {
          homeManagerModules = import ./modules/home-manager;
          darwinModules = import ./modules/darwin;
          nixosModules = import ./modules/nixos;

          darwinConfigurations = {
            mars = mkDarwin "x86_64" [./hosts/mars];
            athena = mkDarwin "aarch64" [./hosts/athena];
          };

          nixosConfigurations = {
            # Hashistack control plane VMs
            megaera = mkNixos [./hosts/megaera];
            tisiphone = mkNixos [./hosts/tisiphone];
            alecto = mkNixos [./hosts/alecto];

            # Raspberry Pis
            arges = mkNixos [./hosts/arges];
            brontes = mkNixos [./hosts/brontes];
            steropes = mkNixos [./hosts/steropes];

            # Other Proxmox VMs
            hypnos = mkNixos [./hosts/hypnos];
            helios = mkNixos [./hosts/helios];

            # Proxmox LXC containers
            orion = mkNixos [./hosts/orion];
            nemesis = mkNixos [./hosts/nemesis];
            aion = mkNixos [./hosts/aion];
            gaia = mkNixos [./hosts/gaia];
            rhea = mkNixos [./hosts/rhea];
            cronus = mkNixos [./hosts/cronus];
          };
        };

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
      }
    );
}
