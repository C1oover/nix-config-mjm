{ inputs, pkgs, ... }:
{

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://nix-community.cachix.org"
      "https://helix.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        nur = import inputs.nur {
          nurpkgs = prev;
          pkgs = prev;
        };
      })
      (import ../../../overlay.nix)
    ];
  };

  nix.package = pkgs.lix;

  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
  nix.registry.nixpkgs.flake.outPath = builtins.storePath pkgs.path;

  programs.nix-index.enable = true;
}
