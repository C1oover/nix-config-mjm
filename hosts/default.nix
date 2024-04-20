{
  self,
  lib,
  inputs,
  ...
}:
let
  inherit (self) outputs;
  mkDarwin =
    arch: modules:
    inputs.darwin.lib.darwinSystem {
      inherit modules;

      system = "${arch}-darwin";
      inputs = {
        inherit (inputs) darwin nixpkgs;
      };
      specialArgs = {
        inherit inputs outputs;
      };
    };
in
{
  flake = {
    darwinConfigurations = {
      mars = mkDarwin "x86_64" [ ./mars ];
      athena = mkDarwin "aarch64" [ ./athena ];
    };

    colmena =
      {
        meta = {
          nixpkgs = inputs.nixos.legacyPackages.x86_64-linux;
          nodeNixpkgs = lib.genAttrs [
            "arges"
            "brontes"
            "steropes"
          ] (_node: inputs.nixos.legacyPackages.aarch64-linux);
          specialArgs = {
            inherit inputs outputs;
          };
        };

        defaults =
          { config, lib, ... }:
          {
            options.deployment.phase = lib.mkOption {
              type = lib.types.enum [
                null
                "main"
                "ingress"
              ];
              default = "main";
            };

            config = {
              deployment = {
                targetHost = lib.mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
                targetUser = "matt";
                tags = lib.mkIf (config.deployment.phase != null) [ "phase-${config.deployment.phase}" ];
              };
            };
          };
      }
      // lib.genAttrs
        [
          "aion"
          "alecto"
          "arges"
          "brontes"
          "chaos"
          "cronus"
          "helios"
          "hypnos"
          "leto"
          "megaera"
          "persephone"
          "rhea"
          "steropes"
          "tisiphone"
          "uranus"
        ]
        (name: {
          imports = [ ./${name} ];
        });
  };

  perSystem =
    {
      pkgs,
      lib,
      system,
      inputs',
      ...
    }:
    let
      # hash mismatch in the go modules for vault rn
      vault = pkgs.vault-bin;
      host-scripts = pkgs.callPackage ./scripts { inherit vault; };
    in
    {
      devenv.shells.default = {
        packages = [ pkgs.colmena ];
      };

      packages = {
        inherit host-scripts;
      };
      apps = lib.genAttrs host-scripts.scripts (script: {
        program = "${host-scripts}/bin/${script}";
      });
    };
}
