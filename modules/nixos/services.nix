{
  config,
  lib,
  pkgs,
  utils,
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

          useSpiffeIdentity = mkEnableOption "per-service SPIFFE identity";

          socketPath = mkOption {
            type = types.path;
            default = "/run/${name}-creds.sock";
            readOnly = true;
          };

          loadedBy = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          keys = mkOption {
            type = types.attrsOf (
              types.submodule (
                { name, ... }:
                {
                  options = {
                    loadedBy = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                    };
                    owner = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                    };
                    # this is copied here because trying to get it from `vault-secrets` introduces infinite recursion
                    path = mkOption {
                      type = types.path;
                      default = "${osConfig.vault-secrets.secretsDir}/services/${svcName}/${name}";
                    };
                  };
                }
              )
            );
            default = { };
          };
        };
      };
    };

  postgresServices = attrValues (filterAttrs (_: s: s.postgresql.enable) cfg);
  vaultServices = attrValues (filterAttrs (_: s: s.vault.enable) cfg);
  legacyVaultServices = filter (s: !s.vault.useSpiffeIdentity) vaultServices;
  spiffeVaultServices = filter (s: s.vault.useSpiffeIdentity) vaultServices;
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

      vault-secrets.services = listToAttrs (
        map (s: nameValuePair s.name { inherit (s.vault) loadedBy keys; }) legacyVaultServices
      );
    })

    (mkIf (spiffeVaultServices != [ ]) {
      systemd.services = pipe spiffeVaultServices [
        (map (
          { name, ... }:
          nameValuePair "${name}-creds" {
            wantedBy = [ "multi-user.target" ];
            after = [
              "network.target"
              "${name}-creds.socket"
            ];
            requires = [ "${name}-creds.socket" ];

            environment = {
              SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
              VAULT_ADDR = "https://vault.service.consul:8200";
            };

            serviceConfig = {
              Type = "notify";
              ExecStart = utils.escapeSystemdExecArgs [
                (lib.getExe pkgs.spire-secrets)
                "-path"
                "prod/services/${name}"
                "server"
              ];
              DynamicUser = true;
            };
          }
        ))
        listToAttrs
      ];

      systemd.sockets = pipe spiffeVaultServices [
        (map (
          { name, ... }:
          nameValuePair "${name}-creds" {
            wantedBy = [ "sockets.target" ];
            partOf = [ "${name}-creds.service" ];
            socketConfig = {
              ListenStream = "/run/${name}-creds.sock";
              SocketMode = "0600";
            };
          }
        ))
        listToAttrs
      ];
    })

  ];
}
