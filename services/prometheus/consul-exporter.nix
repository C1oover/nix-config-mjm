{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.cloover.prometheus;
in
{
  config = mkIf cfg.enable {
    environment.etc."alloy/consul.alloy".source = ./consul.alloy;
  };
}
