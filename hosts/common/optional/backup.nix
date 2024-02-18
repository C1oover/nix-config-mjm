{ lib, config, ... }:
let
  inherit (lib)
    types
    mkIf
    mkMerge
    mkOption
    mkDefault
    ;

  envPath = config.vault-secrets.templates.restic-backup-env.path;
  offsiteEnvPath = config.vault-secrets.templates.restic-backup-offsite-env.path;
in
{
  # set up some default configuration for backup jobs
  options.services.restic.backups = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.offsite = mkOption {
            type = types.bool;
            default = false;
          };
          options.repositoryName = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          config = mkMerge [
            (mkIf (config.repositoryName != null) {
              repository =
                if config.offsite then
                  "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${config.repositoryName}"
                else
                  "s3:http://garage.service.consul:3902/restic-backups/${config.repositoryName}";
            })
            {
              initialize = mkDefault true;
              environmentFile = mkDefault (if config.offsite then offsiteEnvPath else envPath);
              pruneOpts = mkDefault [
                "--keep-daily 7"
                "--keep-weekly 4"
              ];
              timerConfig = mkDefault {
                OnCalendar = "daily";
                RandomizedDelaySec = "2h";
              };
            }
          ];
        }
      )
    );
  };

  config.vault-secrets.templates = {
    restic-backup-env.text = ''
      AWS_DEFAULT_REGION=home
      {{ with secret "kv/restic" }}
      AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
      {{ end }}
    '';
    restic-backup-offsite-env.text = ''
      {{ with secret "kv/restic" }}
      AWS_ACCESS_KEY_ID={{ .Data.data.b2_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.b2_application_key }}
      {{ end }}
    '';
  };
}
