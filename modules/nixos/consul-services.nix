{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  jsonFormat = pkgs.formats.json { };
  cfg = config.services.consul;

  servicesCfg = jsonFormat.generate "consul-services.json" {
    services = builtins.attrValues cfg.services;
  };
in
{
  options.services.consul.services = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          freeformType = jsonFormat.type;

          options.id = mkOption {
            type = types.str;
            default = "${name}:${config.networking.hostName}";
          };
          options.name = mkOption {
            type = types.str;
            default = name;
          };
        }
      )
    );
    default = { };
  };

  config = mkIf (cfg.services != { }) {
    environment.etc."consul-services.json".source = servicesCfg;
    services.consul.extraConfigFiles = [ "/etc/consul-services.json" ];
    systemd.services.consul.reloadTriggers = [ servicesCfg ];
  };
}
