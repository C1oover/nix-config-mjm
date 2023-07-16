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
    };
  };
}
