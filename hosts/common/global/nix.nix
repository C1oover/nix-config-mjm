{inputs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    home-manager.flake = inputs.home-manager;
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nur.overlay
    ];
  };

  programs.nix-index.enable = true;
}
