{
  imports = [
    ./home-manager.nix
    ./ipv6.nix
    ./nix.nix
    ./user.nix
  ];

  programs.fish.enable = true;
}
