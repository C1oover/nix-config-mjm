let
  sources = import ./npins;
  lib = import "${sources.nixos}/lib";

  isLinux = lib.hasSuffix "-linux" builtins.currentSystem;
  pkgs = import sources.${if isLinux then "nixos" else "nixpkgs"} { config.allowUnfree = true; };
in
{
  scripts = pkgs.callPackage ./scripts { };
  host-scripts = pkgs.callPackage ./hosts/scripts { vault = pkgs.vault-bin; };
  inherit (import ./terraform { inherit pkgs; }) tofu-scripts;
}
// (import ./packages { inherit pkgs; })
