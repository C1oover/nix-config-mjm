{
  lib,
  pkgs,
  ...
}:
with lib; let
  optionType = with types;
    attrsOf (submodule ({config, ...}: {
      options.roleId = mkOption {
        type = nullOr str;
        default = null;
      };
      options.secretIdFile = mkOption {
        type = nullOr str;
        default = null;
      };
      options.templates = mkOption {
        type = listOf (attrsOf anything);
        default = [];
      };

      config.settings = mkMerge [
        (mkIf (config.roleId != null && config.secretIdFile != null) {
          vault.address = "http://vault.service.consul:8200";
          auto_auth.method = [
            {
              type = "approle";
              config = {
                remove_secret_id_file_after_reading = false;
                role_id_file_path = "${pkgs.writeText "role-id" config.roleId}";
                secret_id_file_path = config.secretIdFile;
              };
            }
          ];
        })
        (mkIf (config.templates != []) {template = config.templates;})
      ];
    }));
in {
  options.services.vault-agent.instances = mkOption {type = optionType;};
}
