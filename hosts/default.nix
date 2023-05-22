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
}
