{
  self,
  lib,
  inputs,
  ...
}: let
  inherit (self) outputs;
  mkDarwin = arch: modules:
    inputs.darwin.lib.darwinSystem {
      inherit modules;

      system = "${arch}-darwin";
      inputs = {inherit (inputs) darwin nixpkgs;};
      specialArgs = {inherit inputs outputs;};
    };
  mkNixos = modules:
    inputs.nixos.lib.nixosSystem {
      inherit modules;
      specialArgs = {inherit inputs outputs;};
    };
in {
  flake = {
    darwinConfigurations = {
      mars = mkDarwin "x86_64" [./mars];
      athena = mkDarwin "aarch64" [./athena];
    };

    nixosConfigurations = {
      persephone = mkNixos [./persephone];
      nyx = mkNixos [./nyx];
      uranus = mkNixos [./uranus];

      # Hashistack control plane VMs
      megaera = mkNixos [./megaera];
      tisiphone = mkNixos [./tisiphone];
      alecto = mkNixos [./alecto];

      # Raspberry Pis
      arges = mkNixos [./arges];
      brontes = mkNixos [./brontes];
      steropes = mkNixos [./steropes];

      # Other Proxmox VMs
      hypnos = mkNixos [./hypnos];
      helios = mkNixos [./helios];
      chaos = mkNixos [./chaos];
      leto = mkNixos [./leto];

      # Proxmox LXC containers
      rhea = mkNixos [./rhea];
      cronus = mkNixos [./cronus];
      themis = mkNixos [./themis];
    };

    colmena = {
      meta = {
        nixpkgs = inputs.nixos.legacyPackages.x86_64-linux;
        nodeNixpkgs = lib.genAttrs ["arges" "brontes" "steropes"] (_node: inputs.nixos.legacyPackages.aarch64-linux);
        specialArgs = {inherit inputs outputs;};
      };

      defaults = {config, ...}: {
        deployment = {
          targetHost = "${config.networking.hostName}.home.mattmoriarity.com";
          targetUser = "matt";
        };
      };

      arges = {
        deployment.tags = ["builder"];
        imports = [./arges];
      };
      brontes = {
        deployment.tags = ["arm64" "nomad" "ingress"];
        imports = [./brontes];
      };
      steropes = {
        deployment.tags = ["arm64" "nomad" "ingress"];
        imports = [./steropes];
      };

      alecto = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./alecto];
      };
      megaera = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./megaera];
      };
      tisiphone = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./tisiphone];
      };

      chaos = {
        deployment.tags = ["x86_64" "garage"];
        imports = [./chaos];
      };
      helios = {
        deployment.tags = ["x86_64" "garage" "nomad"];
        imports = [./helios];
      };
      hypnos = {
        deployment.tags = ["builder"];
        imports = [./hypnos];
      };
      leto = {
        deployment.tags = ["x86_64" "garage"];
        imports = [./leto];
      };

      rhea = {
        deployment.tags = ["x86_64" "dns"];
        imports = [./rhea];
      };
      cronus = {
        deployment.tags = ["x86_64" "dns"];
        imports = [./cronus];
      };
      themis = {
        deployment.tags = ["x86_64"];
        imports = [./themis];
      };
    };
  };

  perSystem = {
    pkgs,
    lib,
    system,
    inputs',
    ...
  }: let
    attic = inputs'.attic.packages.default;
  in {
    devenv.shells.default = {
      packages = [pkgs.colmena];
    };

    apps = builtins.mapAttrs (_: script: {program = script;}) (pkgs.callPackages ./scripts.nix {
      inherit attic;
    });
  };
}
