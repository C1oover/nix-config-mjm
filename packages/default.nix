{
  sources ? import ../npins,
  pkgs ? import sources.nixos-small { config.allowUnfree = true; },
  ...
}@args:
let
  outpkgs = if (args ? outpkgs) then args.outpkgs else pkgs // packages;
  callPackage =
    if (args ? outpkgs) then args.outpkgs.callPackage else pkgs.lib.callPackageWith outpkgs;

  packages =
    pkgs.lib.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = ./.;
    }
    // {
      oldpkgs = pkgs;
    };
in
# pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [
#   (pythonFinal: pythonPrev: {
#     py-opensonic = pythonPrev.py-opensonic.overridePythonAttrs {
#       version = "5.2.1";
#       src = pkgs.fetchFromGitHub {
#         owner = "khers";
#         repo = "py-opensonic";
#         rev = "v5.2.1";
#         hash = "sha256-lVErs5f2LoCrMNr+f8Bm2Q6xQRNuisloqyRHchYTukk=";
#       };
#     };
#   })
# ];
# };
packages
