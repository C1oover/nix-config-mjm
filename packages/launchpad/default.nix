{
  sources ? import ../../npins/patched.nix,
  pkgs ? import sources.nixos-small { },
}:

pkgs.callPackage ./package.nix { }
