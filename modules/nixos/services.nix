{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    concatMap
    filter
    filterAttrs
    listToAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    pipe
    types
    ;

  cfg = config.mjm.services;
  osConfig = config;

  serviceType =
    { name, ... }:
    let
      svcName = name;
    in
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

        vault = {
          enable = mkEnableOption "Vault service policy";

          socketPath = mkOption {
            type = types.path;
            default = "/run/${name}-creds.sock";
            readOnly = true;
          };
        };
      };
    };

  postgresServices = attrValues (filterAttrs (_: s: s.postgresql.enable) cfg);
  vaultServices = attrValues (filterAttrs (_: s: s.vault.enable) cfg);
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

    (mkIf (vaultServices != [ ]) {
      vault.services = listToAttrs (map (s: nameValuePair s.name { }) vaultServices);

      systemd.sockets = pipe vaultServices [
        (map (
          { name, ... }:
          nameValuePair "spiffe-creds@${name}" {
            overrideStrategy = "asDropin";
            wantedBy = [ "sockets.target" ];
          }
        ))
        listToAttrs
      ];
    })

  ];
}
