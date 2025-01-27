{
  imports = [
    ./home-manager.nix
    ./nix.nix
    ./user.nix
  ];

  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;
}
