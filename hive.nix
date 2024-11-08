let
  sources = import ./npins/patched.nix;
  lib = import "${sources.nixos}/lib";

  hostNames = [
    "aether"
    "aion"
    "alecto"
    "arges"
    "brontes"
    "chaos"
    "erebus"
    "helios"
    "hypnos"
    "leto"
    "megaera"
    "persephone"
    "steropes"
    "tisiphone"
    "uranus"
  ];
  mkHost = name: { imports = [ ./hosts/${name} ]; };
  hosts = lib.genAttrs hostNames mkHost;
in
{
  meta = {
    nixpkgs = sources.nixos-small;
    nodeNixpkgs = {
      uranus = sources.nixos;
      persephone = sources.nixos;
    };

    specialArgs = {
      inputs = sources;
    };
  };

  defaults = {
    imports = [
      ./modules/nixos/deployment.nix
      ./hosts/common/global/nixos
      ./hosts/common/users/matt
    ];
  };
}
// hosts
