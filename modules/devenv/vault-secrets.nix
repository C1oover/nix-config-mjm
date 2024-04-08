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
    getExe
    mkIf
    mkOption
    types
    ;

  cfg = config.vault-secrets;
  secretsDir = config.env.DEVENV_SECRETS;

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
            default = "${secretsDir}/${config.serviceName}_${config.name}";
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
    services = mkOption { type = types.attrsOf (serviceType "services"); };
    common = mkOption { type = types.attrsOf (serviceType "common"); };
  };

  config = mkIf (allKeys != [ ]) {
    env.DEVENV_SECRETS = "${config.env.DEVENV_STATE}/secrets";
    env.CREDENTIALS_DIRECTORY = config.env.DEVENV_SECRETS;

    enterShell = ''
      mkdir -p $DEVENV_SECRETS
      ${concatMapStringsSep "\n" writeSecret allKeys}
    '';
  };
}
