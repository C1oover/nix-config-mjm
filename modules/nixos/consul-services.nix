{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.services.consul;
in
{
  imports = [ ../common/consul-services.nix ];

  config = mkIf (cfg.services != { }) {
    systemd.services.consul.reloadTriggers = [ config.environment.etc."consul-services.json".source ];
  };
}
