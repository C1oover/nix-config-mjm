{
  pkgs,
  lib,
  utils,
  config,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMap
    elem
    filter
    filterAttrs
    genAttrs
    getAttrs
    listToAttrs
    literalExpression
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optional
    optionalString
    unique
    types
    ;

  inherit (utils) systemdUtils;

  cfg = config.vault-secrets;

  mkTemplate = tmplCfg: {
    contents = tmplCfg.text;
    destination = tmplCfg.path;
    user = tmplCfg.owner;
    perms = tmplCfg.mode;
  };

  allTemplates = attrValues cfg.templates;
  loadedByNames = unique (concatMap (tmpl: tmpl.loadedBy) allTemplates);

  consulTemplateConfig = {
    once = true;
    vault.address = cfg.vaultAddress;
    template = map mkTemplate (attrValues cfg.templates);
  };

  allServices = (attrValues cfg.services) ++ (attrValues cfg.common);
  allKeys = concatMap (svc: attrValues svc.keys) allServices;

  format = pkgs.formats.json { };
  cfgFile = format.generate "secrets-template-config.json" consulTemplateConfig;

  templateType = types.submodule (
    { config, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = config._module.args.name;
          defaultText = literalExpression "config._module.args.name";
          description = ''
            Name of the file to render in {option}`vault-secrets.secretsDir`.
          '';
        };
        text = mkOption {
          type = types.str;
          description = ''
            Template to use to render the file's contents from vault.
          '';
        };
        kvPath = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Render file contents from a single key-value entry.

            All but the last path component will be used as the path of the secret. The last
            component will the key to lookup in that secret.

            For example, given a path `"kv/foo/bar/baz"`, an equivalent template would be:

            ```
            {{ with secret "kv/foo/bar" }}{{ .Data.data.baz }}{{ end }}
            ```
          '';
        };
        path = mkOption {
          type = types.str;
          default = "${cfg.secretsDir}/${config.name}";
          defaultText = literalExpression ''
            "''${cfg.secretsDir}/''${config.name}"
          '';
          description = ''
            Path where the rendered secret will be.
          '';
        };
        mode = mkOption {
          type = types.str;
          default = "0400";
          description = ''
            Permissions mode of the rendered secret.
          '';
        };
        owner = mkOption {
          type = types.str;
          default = "root";
          description = ''
            User who will own the rendered secret.
          '';
        };
        loadedBy = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of systemd services that should load this credential.
          '';
        };
        credentialId = mkOption {
          type = types.str;
          default = config._module.args.name;
          description = ''
            ID of the credential when loaded into a systemd service.
          '';
        };
      };

      config.text =
        mkIf (config.kvPath != null)
          ''{{ with secret "${builtins.dirOf config.kvPath}" }}{{ .Data.data.${builtins.baseNameOf config.kvPath} }}{{ end }}'';
    }
  );

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
          };
          serviceName = mkOption {
            type = types.str;
            default = cfg.${config.namespace}.${opts.name}.name;
            readOnly = true;
          };
          path = mkOption {
            type = types.path;
            default = "${cfg.secretsDir}/${config.namespace}/${config.serviceName}/${config.name}";
            internal = true;
          };
          loadedBy = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          owner = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };

        config = {
          loadedBy = cfg.${config.namespace}.${config.serviceName}.loadedBy;
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
          loadedBy = mkOption {
            type = types.listOf types.str;
            default = [ ];
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
    secretsDir = mkOption {
      type = types.path;
      default = "/run/vault-secrets";
      description = ''
        Folder where secrets are rendered.
      '';
    };
    useSpiffe = mkOption {
      type = types.bool;
      default = config.mjm.spire.agent.enable;
    };
    roleId = mkOption {
      type = types.str;
      description = ''
        Role ID for the AppRole to use to log in to Vault.
      '';
    };
    encryptedSecretId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Encrypted systemd credential containing the secret ID for the AppRole to use to log in to Vault.
      '';
    };
    secretIdFile = mkOption {
      type = types.str;
      description = ''
        Path to a file that contains the secret ID for the AppRole to use to log in to Vault.
      '';
    };
    vaultAddress = mkOption {
      type = types.str;
      default =
        if cfg.useSpiffe then "https://vault.service.consul:8250" else "http://vault.service.consul:8200";
      description = ''
        Address to use to communicate with Vault.
      '';
    };
    templates = mkOption {
      type = types.attrsOf templateType;
      default = { };
      description = ''
        Attrset of templates for secrets.
      '';
    };
    services = mkOption {
      type = types.attrsOf (serviceType "services");
      default = { };
      description = ''
        Attrset of services to render secrets for.
      '';
    };
    common = mkOption {
      type = types.attrsOf (serviceType "common");
      default = { };
    };
    wantedBy = mkOption {
      type = types.listOf systemdUtils.lib.unitNameType;
      default = [ ];
      description = ''
        List of systemd unit names that depend on secrets from Vault.
      '';
    };
  };

  config = mkMerge [
    (mkIf (cfg.templates != { }) (mkMerge [
      (mkIf (cfg.encryptedSecretId != null) {
        systemd.services.render-vault-secrets.serviceConfig.LoadCredentialEncrypted = [
          "secret-id:${pkgs.writeText "vault-secret-id" cfg.encryptedSecretId}"
        ];
        vault-secrets.secretIdFile = "$CREDENTIALS_DIRECTORY/secret-id";
      })
      {
        fileSystems."/run/vault-secrets" = {
          device = "none";
          fsType = "ramfs";
          options = [
            "nodev"
            "nosuid"
            "mode=0751"
          ];
        };

        systemd.services.render-vault-secrets = {
          wantedBy = cfg.wantedBy;
          before = cfg.wantedBy;
          after = [ "network-online.target" ] ++ optional cfg.useSpiffe "spire-agent.service";
          wants = [ "network-online.target" ];
          path = with pkgs; [
            vault
            consul-template
            glibc.getent
            spire-agent
            jq
          ];
          preStart = mkIf cfg.useSpiffe ''
            # wait a bit for the spire-agent socket to be available
            for ((i=0; i<5; i++)); do
              [ -S ${config.mjm.spire.agent.socketPath} ] && break
              sleep 2
            done

            spire-agent api fetch -socketPath ${config.mjm.spire.agent.socketPath} -write /run/vault-secrets-certs
          '';
          script = ''
            ${optionalString cfg.useSpiffe ''
              jwt="$(spire-agent api fetch jwt -audience $VAULT_ADDR -output json -socketPath ${config.mjm.spire.agent.socketPath} | jq -r '.[0].svids[0].svid')"
              VAULT_TOKEN="$(vault write -field=token auth/spiffe/login role=spiffe jwt=$jwt)"
            ''}
            ${optionalString (!cfg.useSpiffe) ''
              role_id=${cfg.roleId}
              secret_id_file="${cfg.secretIdFile}"
              VAULT_TOKEN="$(vault write -field=token auth/approle/login role_id=$role_id secret_id=@$secret_id_file)"
            ''}
            export VAULT_TOKEN

            exec consul-template -config ${cfgFile} -exec true
          '';
          environment = {
            VAULT_ADDR = cfg.vaultAddress;
            VAULT_CACERT = mkIf cfg.useSpiffe "/run/vault-secrets-certs/bundle.0.pem";
          };
          startLimitIntervalSec = 0;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "5s";
            RuntimeDirectory = "vault-secrets-certs";
          };
        };
      }
      {
        vault-secrets.wantedBy = map (s: "${s}.service") loadedByNames;

        systemd.services = genAttrs loadedByNames (name: {
          serviceConfig.LoadCredential = map (tmpl: "${tmpl.credentialId}:${tmpl.path}") (
            filter (tmpl: elem name tmpl.loadedBy) allTemplates
          );
        });
      }
    ]))
    {
      vault-secrets.templates = listToAttrs (
        map (
          key:
          nameValuePair "${key.namespace}/${key.serviceName}/${key.name}" (
            {
              kvPath = "kv/prod/${key.namespace}/${key.serviceName}/${key.name}";
              loadedBy = key.loadedBy;
              credentialId = "${key.serviceName}_${key.name}";
            }
            // filterAttrs (_: v: v != null) (getAttrs [ "owner" ] key)
          )
        ) allKeys
      );
    }
  ];
}
