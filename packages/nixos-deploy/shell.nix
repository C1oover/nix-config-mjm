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
      inherit (pkgs.beam.packages.erlang_27) erlang elixir_1_17;
      inherit (pkgs) nix-eval-jobs;
    };
  }
)
