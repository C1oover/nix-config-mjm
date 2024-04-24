let
  inputs = import ../npins;
  lib = import "${inputs.nixpkgs}/lib";
  evalConfig = import "${inputs.darwin}/eval-config.nix";
  mkDarwin =
    arch: modules:
    evalConfig {
      inherit lib;
      modules = modules ++ [
        {
          nixpkgs.system = "${arch}-darwin";
          nixpkgs.source = inputs.nixpkgs;
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
