let
  inputs = import ./npins;
  lib = import "${inputs.nixpkgs}/lib";

  pkgsForPatching = import inputs.nixos { };
  inherit (pkgsForPatching) applyPatches fetchpatch;

  patchNixpkgs =
    {
      src,
      patches ? [ ],
    }:
    applyPatches {
      name = "${src.name}-patched";
      inherit src patches;
    };
in
{
  meta = {
    nixpkgs = inputs.nixos-small;
    nodeNixpkgs =
      let
        patchedNixos = patchNixpkgs {
          src = inputs.nixos;
          patches = [
            # bcachefs-unlock-generator
            (fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/345207.diff";
              hash = "sha256-a1QsPEbcNhjuZr57OyJb+SHhM8T1rNxNJ7L3J2gkbg8=";
            })
            (fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/349783.diff";
              hash = "sha256-cEaZTYY3TGltcUzhOZ8dIXrNuouVblwPr1kwWoRq3M0=";
            })
          ];
        };
      in
      {
        uranus = patchedNixos;
        persephone = patchedNixos;
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
      "aether"
      "aion"
      "alecto"
      "arges"
      "brontes"
      "chaos"
      # "cronus"
      "erebus"
      "helios"
      "hypnos"
      "leto"
      "megaera"
      "persephone"
      # "rhea"
      "steropes"
      "tisiphone"
      "uranus"
    ]
    (name: {
      imports = [ ./hosts/${name} ];
    })
