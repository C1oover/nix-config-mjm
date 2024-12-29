let
  sources = import ../npins/patched.nix;
  lib = import "${sources.nixpkgs}/lib";

  evalConfig = import "${sources.darwin}/eval-config.nix";
  mkDarwin =
    modules:
    evalConfig {
      inherit lib;
      modules = modules ++ [
        ../modules/darwin
        {
          nixpkgs.source = sources.nixpkgs;
          system.checks.verifyNixPath = false;
        }
      ];
      specialArgs = {
        inputs = sources;
        localModulesPath = toString ../modules;
      };
    };
in
{
  athena = mkDarwin [ ./athena ];
  mars = mkDarwin [ ./mars ];
  talos = mkDarwin [ ./talos ];
}
