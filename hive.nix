let
  sources = import ./npins/patched.nix;
  lib = import "${sources.nixos}/lib";
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
      "erebus"
      "helios"
      "hypnos"
      "leto"
      "megaera"
      "persephone"
      "steropes"
      "tisiphone"
      "uranus"
    ]
    (name: {
      imports = [ ./hosts/${name} ];
    })
