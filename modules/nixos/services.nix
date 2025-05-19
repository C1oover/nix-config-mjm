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
    filterAttrs
    listToAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    pipe
    types
    ;

  cfg = config.mjm.services;
  trustDomain = config.mjm.spire.agent.trustDomain;

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

    {
      deployment.tags = map (s: "svc-${s}") (attrNames cfg);

      mjm.spire.entries = mapAttrs' (
        s: _:
        nameValuePair "service-${s}-${config.networking.hostName}" {
          spiffe_id = "spiffe://${trustDomain}/svc/${s}";
          parent_id = "spiffe://${trustDomain}/${config.networking.hostName}";
        }
      ) cfg;
    }

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

      mjm.spire.entries = pipe vaultServices [
        (map (
          { name, ... }:
          nameValuePair "spiffe-creds-${name}" {
            spiffe_id = "spiffe://${trustDomain}/svc/${name}";
            selectors = [
              {
                type = "systemd";
                value = "id:spiffe-creds@${name}.service";
              }
            ];
          }
        ))
        listToAttrs
      ];
    })

  ];
}
