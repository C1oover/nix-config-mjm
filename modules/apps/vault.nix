{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    genAttrs
    getAttr
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.vault;

  jsonFormat = pkgs.formats.json { };

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

  databaseRoleType =
    { name, ... }:
    {
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
          type =
            types.either
              (types.enum [
                "short"
                "long"
              ])
              (
                types.submodule {
                  options = {
                    default = mkOption { type = types.int; };
                    max = mkOption { type = types.int; };
                  };
                }
              );
        };
      };
    };

  approleType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        tokenPolicies = mkOption {
          type = types.listOf types.str;
          default = [ name ];
        };
      };
    };

  policyType =
    { name, ... }:
    {
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
        paths = mkOption {
          default = { };
          type = types.attrsOf jsonFormat.type;
        };
        approles = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };

  serviceType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        hosts = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        paths = mkOption {
          default = { };
          type = types.attrsOf jsonFormat.type;
        };
        commonPolicies = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };
in
{
  options.vault = {
    databases = {
      enable = mkEnableOption "vault's database secret backend";
      roles = mkOption {
        default = { };
        type = types.attrsOf (types.submodule databaseRoleType);
      };
    };
    approles = {
      enable = mkEnableOption "vault's approle auth method";
      roles = mkOption {
        default = { };
        type = types.attrsOf (types.submodule approleType);
      };
    };
    policies = mkOption {
      type = types.attrsOf (types.submodule policyType);
      default = { };
    };
    services = mkOption {
      type = types.attrsOf (types.submodule serviceType);
      default = { };
    };
  };

  config =
    let
      mkPgCreationStatements = roleName: [
        ''create role "{{name}}" with login password '{{password}}' valid until '{{expiration}}'; grant ${roleName} to "{{name}}"; alter role "{{name}}" set role ${roleName};''
      ];
      mkTtlOpts =
        ttl:
        if (builtins.isString ttl) && (builtins.hasAttr ttl ttlPresets) then
          getAttr ttl ttlPresets
        else
          {
            default_ttl = ttl.default;
            max_ttl = ttl.max;
          };

      databases = mkIf cfg.databases.enable {
        terraform.resource.vault_mount.database = {
          path = "database";
          type = "database";
        };

        terraform.resource.vault_database_secret_backend_role = builtins.mapAttrs (
          name:
          { roleName, ttl, ... }:
          let
            ttlOpts = mkTtlOpts ttl;
          in
          {
            inherit name;
            backend = "\${vault_mount.database.path}";
            db_name = "db1";
            creation_statements = mkPgCreationStatements roleName;
          }
          // ttlOpts
        ) cfg.databases.roles;
      };

      approles = mkIf cfg.approles.enable {
        terraform.resource.vault_auth_backend.approle = {
          type = "approle";
        };

        terraform.resource.vault_approle_auth_backend_role = builtins.mapAttrs (
          name:
          { tokenPolicies, ... }:
          {
            backend = "\${vault_auth_backend.approle.id}";
            role_name = name;
            token_policies = tokenPolicies;
          }
        ) cfg.approles.roles;
      };

      policies = {
        terraform.resource.vault_policy = builtins.mapAttrs (
          name:
          {
            text,
            source,
            paths,
            ...
          }:
          {
            inherit name;
            policy =
              if paths != { } then
                builtins.toJSON { path = paths; }
              else if source != null then
                builtins.readFile source
              else
                text;
          }
        ) cfg.policies;

        vault.approles.roles = mkMerge (
          map (
            policy:
            lib.genAttrs policy.approles (_name: {
              tokenPolicies = [ policy.name ];
            })
          ) (builtins.attrValues cfg.policies)
        );
      };

      services = {
        vault.policies = mkMerge (
          mapAttrsToList (
            _: svc:
            {
              "service-${svc.name}" = mkMerge [
                { paths."kv/data/prod/services/${svc.name}".capabilities = [ "read" ]; }
                {
                  inherit (svc) paths;
                  approles = svc.hosts;
                }
              ];
            }
            // (genAttrs (map (name: "common-${name}") svc.commonPolicies) (name: {
              approles = svc.hosts;
            }))
          ) cfg.services
        );
      };
    in
    mkMerge [
      databases
      approles
      policies
      services
    ];
}
