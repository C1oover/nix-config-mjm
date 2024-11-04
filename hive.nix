let
  inputs = import ./npins;
  lib = import "${inputs.nixpkgs}/lib";

  pkgsForPatching = import inputs.nixos { };
  inherit (pkgsForPatching) applyPatches fetchpatch;

  patches = import ./hosts/patches.nix;
  mkPatches =
    kind:
    lib.mapAttrsToList (
      name: value: fetchpatch ({ url = "https://github.com/NixOS/nixpkgs/pull/${name}.diff"; } // value)
    ) (patches.${kind} or { });
  globalPatches = mkPatches "global";

  patchNixpkgs =
    {
      src,
      kind,
      extraPatches ? [ ],
    }:
    let
      allPatches = globalPatches ++ mkPatches kind ++ extraPatches;
    in
    if allPatches == [ ] then
      src
    else
      applyPatches {
        name = "${src.name}-patched";
        patches = allPatches;
        inherit src;
      };

  serverNixpkgs = patchNixpkgs {
    src = inputs.nixos-small;
    kind = "servers";
  };
  desktopNixpkgs = patchNixpkgs {
    src = inputs.nixos;
    kind = "desktops";
  };
in
{
  meta = {
    nixpkgs = serverNixpkgs;
    nodeNixpkgs = {
      uranus = desktopNixpkgs;
      persephone = desktopNixpkgs;
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
