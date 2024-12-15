{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMap
    concatMapStringsSep
    filter
    getExe
    mkIf
    mkOption
    pipe
    types
    ;

  cfg = config.vault-secrets;

  allServices = (attrValues cfg.services) ++ (attrValues cfg.common);
  allKeys = concatMap (svc: attrValues svc.keys) allServices;

  vault = getExe pkgs.vault-bin;
  getSecret = key: "${vault} kv get -mount=kv -field=${key.vaultField} ${key.vaultPath}";
  writeSecret = key: "${getSecret key} > ${key.path}";

  keyType =
    opts:
    types.submodule (
      { name, config, ... }:
      {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
          };
          envVarName = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          namespace = mkOption {
            type = types.str;
            default = opts.namespace;
            readOnly = true;
          };
          serviceName = mkOption {
            type = types.str;
            default = cfg.${config.namespace}.${opts.name}.name;
            readOnly = true;
          };
          path = mkOption {
            type = types.str;
            default = "$SECRETS_DIR/${config.serviceName}_${config.name}";
            readOnly = true;
          };
          vaultPath = mkOption {
            type = types.str;
            default = "prod/${config.namespace}/${config.serviceName}";
            readOnly = true;
          };
          vaultField = mkOption {
            type = types.str;
            default = config.name;
            readOnly = true;
          };
        };
      }
    );

  serviceType =
    namespace:
    types.submodule (
      { name, ... }:
      {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
          };
          keys = mkOption {
            type = types.attrsOf (keyType {
              inherit namespace name;
            });
            default = { };
          };
        };
      }
    );
in
{
  options.vault-secrets = {
    services = mkOption {
      type = types.attrsOf (serviceType "services");
      default = { };
    };
    common = mkOption {
      type = types.attrsOf (serviceType "common");
      default = { };
    };
  };

  config = mkIf (allKeys != [ ]) {
    env =
      [
        {
          name = "SECRETS_DIR";
          eval = "$PRJ_DATA_DIR/secrets";
        }
      ]
      ++ pipe allKeys [
        (filter (key: key.envVarName != null))
        (map (key: {
          name = key.envVarName;
          eval = key.path;
        }))
      ];

    devshell.startup.secrets.text = ''
      mkdir -p $SECRETS_DIR
      ${concatMapStringsSep "\n" writeSecret allKeys}
    '';
  };
}
