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
      (fetchpatch {
        # loki skip config validation
        url = "https://github.com/NixOS/nixpkgs/pull/312785.diff";
        hash = "sha256-lmkS2QM6MeACJlk4yMT7CqEo4eVWDecaRjYVmNxK4fE=";
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
    let
      phases = [
        null
        "main"
        "ingress"
      ];
    in
    {
      options.deployment = {
        phase = lib.mkOption {
          type = lib.types.enum phases;
          default = "main";
        };
        rebootPhase = lib.mkOption {
          type = lib.types.enum phases;
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
