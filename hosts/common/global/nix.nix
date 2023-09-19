{inputs, ...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    substituters = [
      "https://devenv.cachix.org"
      "https://helix.cachix.org"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    home-manager.flake = inputs.home-manager;
  };

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nur.overlay
    ];
  };

  programs.nix-index.enable = true;
}
