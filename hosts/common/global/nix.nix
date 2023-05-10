{ inputs, ... }: {
  nix.configureBuildUsers = true;
  nix.settings = {
    trusted-users = [ "@admin" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    home-manager.flake = inputs.home-manager;
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  services.nix-daemon.enable = true;
}
