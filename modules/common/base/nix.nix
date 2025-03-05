{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) isStorePath mkIf;
  nix-index = import inputs.nix-index-database { inherit pkgs; };
  addNixPath = isStorePath pkgs.path;
in
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
        rycee = import inputs.rycee { pkgs = final; };
      })
      (import ../../../overlay.nix)
    ];
  };

  nix.package = pkgs.lix;

  nix.nixPath = mkIf addNixPath [ "nixpkgs=flake:nixpkgs" ];
  nix.registry.nixpkgs.flake.outPath = mkIf addNixPath (builtins.storePath pkgs.path);

  programs.nix-index = {
    enable = true;
    package = nix-index.nix-index-with-db;
  };
  environment.systemPackages = [ nix-index.comma-with-db ];
}
