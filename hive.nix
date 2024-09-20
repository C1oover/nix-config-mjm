let
  inputs = import ./npins;
  lib = import "${inputs.nixpkgs}/lib";

in
# pkgsForPatching = import inputs.nixos { };
# inherit (pkgsForPatching) applyPatches fetchpatch;
#
# patchNixpkgs =
#   {
#     src,
#     patches ? [ ],
#   }:
#   applyPatches {
#     name = "${src.name}-patched";
#     inherit src;
#     patches = [
#
#     ] ++ patches;
#   };
{
  meta = {
    nixpkgs = inputs.nixos-small;
    nodeNixpkgs = {
      uranus = inputs.nixos;
      persephone = inputs.nixos;
    };

    specialArgs = {
      inherit inputs;
    };
  };

  defaults =
    { config, lib, ... }:
    let
      phases = [
        null
        "main"
        "ingress"
      ];
      rebootPhases = phases ++ [ "vault" ];
    in
    {
      options.deployment = {
        phase = lib.mkOption {
          type = lib.types.enum phases;
          default = "main";
        };
        rebootPhase = lib.mkOption {
          type = lib.types.enum rebootPhases;
          default = config.deployment.phase;
        };
      };

      config = {
        deployment = {
          targetHost = lib.mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
          targetUser = "matt";
          tags =
            lib.optional (config.deployment.phase != null) "phase-${config.deployment.phase}"
            ++ lib.optional (
              config.deployment.rebootPhase != null
            ) "reboot-phase-${config.deployment.rebootPhase}";
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
