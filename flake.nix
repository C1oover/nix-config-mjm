{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.inputs.darwin.follows = "darwin";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-unstable, home-manager, agenix, ... }@inputs:
    let
      nixpkgsConfig = {
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.mars = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        inputs = {
          inherit darwin;
          nixpkgs = nixpkgs-unstable;
        };

        modules = [
          {
            networking.computerName = "Mars";
            networking.hostName = "mars";

            time.timeZone = "America/Denver";

            nix.configureBuildUsers = true;
            nix.settings = {
              trusted-users = [ "@admin" ];
              experimental-features = [ "nix-command" "flakes" ];
            };

            nixpkgs = nixpkgsConfig;

            programs.zsh.enable = true;
            programs.nix-index.enable = true;
            services.nix-daemon.enable = true;

            security.pam.enableSudoTouchIdAuth = true;

            users.users.matt = {
              home = "/Users/matt";
            };

            system.keyboard.enableKeyMapping = true;
            system.keyboard.remapCapsLockToControl = true;

            environment.systemPackages = [ agenix.packages.x86_64-darwin.default ];
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.matt = ./personal.nix;
          }
          agenix.darwinModules.default
          {
            age.secrets.nomad-token = {
              file = secrets/nomad-token.age;
              owner = "matt";
            };
          }
        ];
      };
    };
}
