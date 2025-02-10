{
  imports = [
    ./home-manager.nix
    ./nix.nix
    ./user.nix
  ];

  programs.fish.enable = true;
}
