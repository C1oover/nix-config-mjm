{ config, lib, ... }:
let
  inherit (lib) attrNames mkOption types;

  cfg = config.mjm.services;

  serviceType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
      };
    };
in
{
  options.mjm.services = mkOption {
    default = { };
    type = types.attrsOf (types.submodule serviceType);
  };

  config = {
    deployment.tags = map (s: "svc-${s}") (attrNames cfg);
  };
}
