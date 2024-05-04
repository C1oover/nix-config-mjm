let
  inputs = import ./npins;
  lib = import "${inputs.nixpkgs}/lib";

  pkgsForPatching = import inputs.nixos { };
  inherit (pkgsForPatching) applyPatches fetchpatch;
  nixos-patched = applyPatches {
    name = "nixos-patched";
    src = inputs.nixos;
    patches = [
      (fetchpatch {
        # consul services
        url = "https://github.com/NixOS/nixpkgs/pull/309084.diff";
        hash = "sha256-3yfi8XuoM7EB8OpiwNxAi10KTf1o50Yakv1NylCu7cs=";
      })
    ];
  };
in
{
  meta = {
    nixpkgs = nixos-patched;
    specialArgs = {
      inherit inputs;
    };
  };

  defaults =
    { config, lib, ... }:
    {
      options.deployment.phase = lib.mkOption {
        type = lib.types.enum [
          null
          "main"
          "ingress"
        ];
        default = "main";
      };

      config = {
        deployment = {
          targetHost = lib.mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
          targetUser = "matt";
          tags = lib.mkIf (config.deployment.phase != null) [ "phase-${config.deployment.phase}" ];
        };
      };
    };
}
//
  lib.genAttrs
    [
      "aion"
      "alecto"
      "arges"
      "brontes"
      "chaos"
      "cronus"
      "helios"
      "hypnos"
      "leto"
      "megaera"
      "persephone"
      "rhea"
      "steropes"
      "tisiphone"
      "uranus"
    ]
    (name: {
      imports = [ ./hosts/${name} ];
    })
