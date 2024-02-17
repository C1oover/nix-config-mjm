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
in
{
  # set up some default configuration for backup jobs
  options.services.restic.backups = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.repositoryName = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          config = mkMerge [
            (mkIf (config.repositoryName != null) {
              repository = "s3:http://garage.service.consul:3902/restic-backups/${config.repositoryName}";
            })
            {
              initialize = mkDefault true;
              environmentFile = mkDefault envPath;
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

  config.vault-secrets.templates.restic-backup-env.text = ''
    AWS_DEFAULT_REGION=home
    {{ with secret "kv/restic" }}
    AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
    AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
    {{ end }}
  '';
}
