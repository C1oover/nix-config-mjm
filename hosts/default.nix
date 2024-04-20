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
  mkNixos =
    modules:
    inputs.nixos.lib.nixosSystem {
      inherit modules;
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

    nixosConfigurations = {
      persephone = mkNixos [ ./persephone ];
      uranus = mkNixos [ ./uranus ];
      aion = mkNixos [ ./aion ];

      # Hashistack control plane VMs
      megaera = mkNixos [ ./megaera ];
      tisiphone = mkNixos [ ./tisiphone ];
      alecto = mkNixos [ ./alecto ];

      # Raspberry Pis
      arges = mkNixos [ ./arges ];
      brontes = mkNixos [ ./brontes ];
      steropes = mkNixos [ ./steropes ];

      # Other Proxmox VMs
      hypnos = mkNixos [ ./hypnos ];
      helios = mkNixos [ ./helios ];
      chaos = mkNixos [ ./chaos ];
      leto = mkNixos [ ./leto ];

      # Proxmox LXC containers
      rhea = mkNixos [ ./rhea ];
      cronus = mkNixos [ ./cronus ];
    };

    colmena = {
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
          deployment = {
            targetHost = lib.mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
            targetUser = "matt";
          };
        };

      arges = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./arges ];
      };
      brontes = {
        deployment.tags = [ "phase-ingress" ];
        imports = [ ./brontes ];
      };
      steropes = {
        deployment.tags = [ "phase-ingress" ];
        imports = [ ./steropes ];
      };

      alecto = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./alecto ];
      };
      megaera = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./megaera ];
      };
      tisiphone = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./tisiphone ];
      };

      chaos = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./chaos ];
      };
      helios = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./helios ];
      };
      hypnos = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./hypnos ];
      };
      leto = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./leto ];
      };
      aion = {
        deployment.tags = [ "phase-main" ];
        deployment.targetHost = "5.78.46.61";
        imports = [ ./aion ];
      };

      rhea = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./rhea ];
      };
      cronus = {
        deployment.tags = [ "phase-main" ];
        imports = [ ./cronus ];
      };
    };
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
