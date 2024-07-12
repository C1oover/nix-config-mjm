let
  inputs = import ../npins;
  lib = import "${inputs.nixpkgs}/lib";

  pkgsForPatching = import inputs.nixpkgs { };
  inherit (pkgsForPatching) applyPatches fetchpatch;

  evalConfig = import "${inputs.darwin}/eval-config.nix";
  mkDarwin =
    arch: modules:
    evalConfig {
      inherit lib;
      modules = modules ++ [
        {
          nixpkgs.system = "${arch}-darwin";
          # nixpkgs.source = inputs.nixpkgs;
          nixpkgs.source = applyPatches {
            name = "nixpkgs-patched";
            src = inputs.nixpkgs;
            patches = [
              (fetchpatch {
                # fix swift
                url = "https://github.com/NixOS/nixpkgs/pull/326588.diff";
                hash = "sha256-Q0VOAEekgfOaNLd5GpC0dCsU4BXRanEwGYN2Ye5r0uc=";
              })
            ];
          };
          system.checks.verifyNixPath = false;
        }
      ];
      specialArgs = {
        inherit inputs;
      };
    };
in
{
  athena = mkDarwin "aarch64" [ ./athena ];
}
