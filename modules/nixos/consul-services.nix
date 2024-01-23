{
  pkgs,
  lib,
  config,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };
  cfg = config.services.consul;
in
with lib;
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

  config.services.consul.extraConfigFiles =
    lib.attrsets.mapAttrsToList
      (name: service: toString (jsonFormat.generate "${name}.json" { inherit service; }))
      cfg.services;
}
