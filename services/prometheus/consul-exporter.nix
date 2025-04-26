{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.prometheus;
in
{
  config = mkIf cfg.enable {
    environment.etc."alloy/consul.alloy".source = ./consul.alloy;
  };
}
