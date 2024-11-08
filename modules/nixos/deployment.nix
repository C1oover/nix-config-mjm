{ config, lib, ... }:
let
  inherit (lib)
    mkDefault
    mkOption
    optional
    types
    ;
  cfg = config.deployment;

  phases = [
    null
    "main"
    "ingress"
  ];
  rebootPhases = phases ++ [ "vault" ];
in
{
  options.deployment = {
    phase = mkOption {
      type = types.enum phases;
      default = "main";
    };
    rebootPhase = mkOption {
      type = types.enum rebootPhases;
      default = cfg.phase;
    };
  };

  config = {
    deployment = {
      targetHost = mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
      targetUser = "matt";
      tags =
        optional (cfg.phase != null) "phase-${cfg.phase}"
        ++ optional (cfg.rebootPhase != null) "reboot-phase-${cfg.rebootPhase}";
    };
  };
}
