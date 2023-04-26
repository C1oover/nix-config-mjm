{
  nix.configureBuildUsers = true;
  nix.settings = {
    trusted-users = [ "@admin" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  services.nix-daemon.enable = true;
}
