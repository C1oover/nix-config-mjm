let
  sources = import ../npins/patched.nix;
  lib = import "${sources.nixpkgs}/lib";

  evalConfig = import "${sources.darwin}/eval-config.nix";
  mkDarwin =
    arch: modules:
    evalConfig {
      inherit lib;
      modules = modules ++ [
        {
          nixpkgs.system = "${arch}-darwin";
          nixpkgs.source = sources.nixpkgs;
          system.checks.verifyNixPath = false;
        }
      ];
      specialArgs = {
        inputs = sources;
        localModulesPath = ../modules;
      };
    };
in
{
  athena = mkDarwin "aarch64" [ ./athena ];
  mars = mkDarwin "x86_64" [ ./mars ];
  talos = mkDarwin "x86_64" [ ./talos ];
}
