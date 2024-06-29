{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    attrValues
    concatMap
    filterAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.mjm.services;

  serviceType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        postgresql = {
          enable = mkEnableOption "PostgreSQL for the service";
          databases = mkOption {
            type = types.listOf types.str;
            default = [ name ];
          };
        };
      };
    };

  postgresServices = attrValues (filterAttrs (_: s: s.postgresql.enable) cfg);
in
{
  options.mjm.services = mkOption {
    default = { };
    type = types.attrsOf (types.submodule serviceType);
  };

  config = mkMerge [
    { deployment.tags = map (s: "svc-${s}") (attrNames cfg); }
    (mkIf (postgresServices != [ ]) {
      mjm.postgresql.enable = true;

      services.postgresql = {
        ensureDatabases = concatMap (s: s.postgresql.databases) postgresServices;
        ensureUsers = concatMap (
          s:
          map (d: {
            name = d;
            ensureDBOwnership = true;
          }) s.postgresql.databases
        ) postgresServices;
      };
    })
  ];
}
