let
  sources = import ./npins;
  lib = import "${sources.nixos}/lib";

  isLinux = lib.hasSuffix "-linux" builtins.currentSystem;
  nixpkgs = sources.${if isLinux then "nixos" else "nixpkgs"};
  pkgs = import nixpkgs { config.allowUnfree = true; };

  appsFromScripts =
    pkg:
    lib.genAttrs (pkg.scripts or [ ]) (
      name:
      pkg.overrideAttrs (_oldAttrs: {
        meta.mainProgram = name;
      })
    );

  scripts = pkgs.callPackage ./scripts { };
  host-scripts = pkgs.callPackage ./hosts/scripts { vault = pkgs.vault-bin; };
  inherit (import ./terraform { inherit pkgs; }) tofu-scripts;

  allScripts = {
    inherit scripts host-scripts tofu-scripts;
  };
in
allScripts
// (import ./packages { inherit pkgs; })
// (lib.concatMapAttrs (_name: appsFromScripts) allScripts)
