{
  sources ? import ../../npins/patched.nix,
  pkgs ? import sources.nixos-small { },
  devshell ? import sources.devshell { nixpkgs = pkgs; },
}:

devshell.mkShell (
  { pkgs, lib, ... }:
  let
    inherit (lib) attrValues;
  in
  {
    packages = attrValues {
      inherit (pkgs) erlang elixir nix-eval-jobs;
    };
  }
)
