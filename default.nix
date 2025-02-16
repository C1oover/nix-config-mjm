let
  sources = import ./npins;
  lib = import "${sources.nixos}/lib";

  isLinux = lib.hasSuffix "-linux" builtins.currentSystem;
  nixpkgs = sources.${if isLinux then "nixos" else "nixpkgs"};
  pkgs = import nixpkgs { config.allowUnfree = true; };

  myPkgs = import ./packages { inherit pkgs; };
in
myPkgs
