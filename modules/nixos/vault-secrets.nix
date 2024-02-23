{
  pkgs,
  lib,
  utils,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkMerge
    mkOption
    literalExpression
    ;

  inherit (utils) systemdUtils;

  cfg = config.vault-secrets;

  mkTemplate = tmplCfg: {
    contents = tmplCfg.text;
    destination = tmplCfg.path;
    user = tmplCfg.owner;
    perms = tmplCfg.mode;
  };

  consulTemplateConfig = {
    once = true;
    vault.address = cfg.vaultAddress;
    template = map mkTemplate (builtins.attrValues cfg.templates);
  };

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
      };

      config.text =
        mkIf (config.kvPath != null)
          ''{{ with secret "${builtins.dirOf config.kvPath}" }}{{ .Data.data.${builtins.baseNameOf config.kvPath} }}{{ end }}'';
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
    roleId = mkOption {
      type = types.str;
      description = ''
        Role ID for the AppRole to use to log in to Vault.
      '';
    };
    secretIdFile = mkOption {
      type = types.path;
      description = ''
        Path to a file that contains the secret ID for the AppRole to use to log in to Vault.
      '';
    };
    secretIdAgeFile = mkOption {
      type = types.nullOr types.str;
      default = "${config.networking.hostName}-approle-secret-id.age";
    };
    vaultAddress = mkOption {
      type = types.str;
      default = "http://vault.service.consul:8200";
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
    wantedBy = mkOption {
      type = types.listOf systemdUtils.lib.unitNameType;
      default = [ ];
      description = ''
        List of systemd unit names that depend on secrets from Vault.
      '';
    };
  };

  config = mkIf (cfg.templates != { }) (
    mkMerge [
      (mkIf (cfg.secretIdAgeFile != null) {
        age.secrets.vault-secrets-approle-secret-id.file = ../../secrets/${cfg.secretIdAgeFile};
        vault-secrets.secretIdFile = config.age.secrets.vault-secrets-approle-secret-id.path;
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
          wantedBy = [ "multi-user.target" ] ++ cfg.wantedBy;
          before = cfg.wantedBy;
          after = [ "network.target" ];
          path = with pkgs; [
            vault
            consul-template
            glibc.getent
          ];
          script = ''
            role_id=${cfg.roleId}
            secret_id="$(cat ${cfg.secretIdFile})"

            VAULT_TOKEN="$(vault write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)"
            export VAULT_TOKEN

            exec consul-template -config ${cfgFile} -exec true
          '';
          environment = {
            VAULT_ADDR = cfg.vaultAddress;
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };
      }
    ]
  );
}
