{
  self,
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
    inputs.nixpkgs.lib.nixosSystem {
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

      # Proxmox LXC containers
      orion = mkNixos [./orion];
      nemesis = mkNixos [./nemesis];
      aion = mkNixos [./aion];
      gaia = mkNixos [./gaia];
      rhea = mkNixos [./rhea];
      cronus = mkNixos [./cronus];
      phoebe = mkNixos [./phoebe];
      themis = mkNixos [./themis];
      thanatos = mkNixos [./thanatos];
    };

    deploy = {
      user = "root";
      sshUser = "matt";
      sshOpts = ["-i" "/home/matt/.ssh/yubikey-cert.pub"];
      nodes = let
        mkNode = name: cfg: let
          nixos = outputs.nixosConfigurations.${name};
        in
          {
            hostname = "${nixos.config.networking.hostName}.home.mattmoriarity.com";
            profiles.system.path = inputs.deploy-rs.lib.${nixos.config.nixpkgs.hostPlatform.system}.activate.nixos nixos;
          }
          // cfg;
      in {
        aion = mkNode "aion" {};
        alecto = mkNode "alecto" {};
        arges = mkNode "arges" {};
        brontes = mkNode "brontes" {};
        cronus = mkNode "cronus" {};
        gaia = mkNode "gaia" {};
        helios = mkNode "helios" {};
        hypnos = mkNode "hypnos" {};
        megaera = mkNode "megaera" {};
        nemesis = mkNode "nemesis" {};
        nyx = mkNode "nyx" {
          hostname = "129.146.64.18";
          sshUser = "root";
          sshOpts = [];
        };
        orion = mkNode "orion" {};
        phoebe = mkNode "phoebe" {};
        rhea = mkNode "rhea" {};
        steropes = mkNode "steropes" {};
        thanatos = mkNode "thanatos" {};
        themis = mkNode "themis" {};
        tisiphone = mkNode "tisiphone" {};
      };
    };
  };

  perSystem = {system, ...}: {
    devenv.shells.default = {
      packages = [inputs.deploy-rs.packages.${system}.default];
    };
  };
}
