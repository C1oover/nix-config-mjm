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
      inherit src;
      patches = [
        (fetchpatch {
          # consul services
          url = "https://github.com/NixOS/nixpkgs/pull/309084.diff";
          hash = "sha256-3yfi8XuoM7EB8OpiwNxAi10KTf1o50Yakv1NylCu7cs=";
        })
      ] ++ patches;
    };
in
{
  meta = {
    nixpkgs = patchNixpkgs {
      src = inputs.nixos-small;
      patches = [
        (fetchpatch {
          url = "https://github.com/NixOS/nixpkgs/pull/336426.diff";
          hash = "sha256-RBEG6EmzAgk42O0UJccOkRAPPo6/AswdVIim3UPd2jg=";
        })
      ];
    };
    nodeNixpkgs =
      let
        nixos = patchNixpkgs { src = inputs.nixos; };
      in
      {
        uranus = nixos;
        persephone = nixos;
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
