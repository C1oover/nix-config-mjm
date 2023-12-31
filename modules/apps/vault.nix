{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.vault;

  hoursToSecs = hours: hours * 3600;
  daysToSecs = days: hoursToSecs (days * 24);

  ttlPresets = {
    short = {
      default_ttl = hoursToSecs 1;
      max_ttl = daysToSecs 1;
    };
    long = {
      default_ttl = daysToSecs 1;
      max_ttl = daysToSecs 7;
    };
  };

  databaseRoleType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        roleName = mkOption {
          type = types.str;
          default = name;
        };
        ttl = mkOption {
          type = types.either (types.enum ["short" "long"]) (types.submodule {
            options = {
              default = mkOption {
                type = types.int;
              };
              max = mkOption {
                type = types.int;
              };
            };
          });
        };
      };
    };

  approleType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        tokenPolicies = mkOption {
          type = types.listOf types.str;
          default = [name];
        };
      };
    };

  policyType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
        };
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
        };
      };
    };
in {
  options.vault = {
    databases = {
      enable = mkEnableOption "vault's database secret backend";
      roles = mkOption {
        default = {};
        type = types.attrsOf (types.submodule databaseRoleType);
      };
    };
    approles = {
      enable = mkEnableOption "vault's approle auth method";
      roles = mkOption {
        default = {};
        type = types.attrsOf (types.submodule approleType);
      };
    };
    policies = mkOption {
      type = types.attrsOf (types.submodule policyType);
      default = {};
    };
  };

  config = let
    mkPgCreationStatements = roleName: [
      "create role \"{{name}}\" with login password '{{password}}' valid until '{{expiration}}'; grant ${roleName} to \"{{name}}\"; alter role \"{{name}}\" set role ${roleName};"
    ];
    mkTtlOpts = ttl:
      if (builtins.isString ttl) && (builtins.hasAttr ttl ttlPresets)
      then getAttr ttl ttlPresets
      else {
        default_ttl = ttl.default;
        max_ttl = ttl.max;
      };

    databases = mkIf cfg.databases.enable {
      terraform.resource.vault_mount.database = {
        path = "database";
        type = "database";
      };

      terraform.resource.vault_database_secret_backend_role =
        builtins.mapAttrs
        (name: {
          roleName,
          ttl,
          ...
        }: let
          ttlOpts = mkTtlOpts ttl;
        in
          {
            inherit name;
            backend = "\${vault_mount.database.path}";
            db_name = "db1";
            creation_statements = mkPgCreationStatements roleName;
          }
          // ttlOpts)
        cfg.databases.roles;
    };

    approles = mkIf cfg.approles.enable {
      terraform.resource.vault_auth_backend.approle = {
        type = "approle";
      };

      terraform.resource.vault_approle_auth_backend_role =
        builtins.mapAttrs
        (name: {tokenPolicies, ...}: {
          backend = "\${vault_auth_backend.approle.id}";
          role_name = name;
          token_policies = tokenPolicies;
        })
        cfg.approles.roles;
    };

    policies = {
      terraform.resource.vault_policy =
        builtins.mapAttrs
        (name: {
          text,
          source,
          ...
        }: {
          inherit name;
          policy =
            if source != null
            then builtins.readFile source
            else text;
        })
        cfg.policies;
    };
  in
    mkMerge [databases approles policies];
}
