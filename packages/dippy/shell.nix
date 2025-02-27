{
  sources ? import ../../npins,
  pkgs ? import sources.nixos-small { overlays = [ (import ../../overlay.nix) ]; },
  devshell ? import sources.devshell { nixpkgs = pkgs; },
}:

devshell.mkShell (
  { pkgs, lib, ... }:
  let
    inherit (lib) attrValues;
  in
  {
    packages = attrValues {
      inherit (pkgs)
        go
        gopls
        nix-eval-jobs
        nvd-json
        ;
    };
  }
)
