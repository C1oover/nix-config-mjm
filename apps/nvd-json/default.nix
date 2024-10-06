let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos-small { },
}:
pkgs.callPackage ./package.nix { }
