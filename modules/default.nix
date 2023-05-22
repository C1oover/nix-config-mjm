{
  flake = {
    homeManagerModules = import ./home-manager;
    darwinModules = import ./darwin;
    nixosModules = import ./nixos;
  };
}
