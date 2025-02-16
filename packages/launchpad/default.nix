{
  sources ? import ../../npins,
  pkgs ? import sources.nixos-small { },
}:

pkgs.callPackage ./package.nix { }
