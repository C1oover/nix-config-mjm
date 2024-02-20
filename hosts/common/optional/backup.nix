{
  lib,
  config,
  options,
  ...
}:
let
  inherit (lib)
    types
    mkMerge
    mkOption
    mapAttrs
    mapAttrs'
    nameValuePair
    ;

  cfg = config.mjm.backups;

  envPath = config.vault-secrets.templates.restic-backup-env.path;
  offsiteEnvPath = config.vault-secrets.templates.restic-backup-offsite-env.path;
in
{
  options.mjm.backups = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            inherit (options.services.restic.backups.type.getSubOptions [ ])
              passwordFile
              paths
              exclude
              user
              backupPrepareCommand
              backupCleanupCommand
              ;

            repositoryName = mkOption {
              type = types.str;
              default = name;
            };
          };
        }
      )
    );
  };

  config.services.restic.backups =
    mapAttrs
      (
        name: cfg:
        mkMerge [
          (removeAttrs cfg [ "repositoryName" ])
          {
            repository = "s3:http://garage.service.consul:3902/restic-backups/${cfg.repositoryName}";
            environmentFile = envPath;
            initialize = true;
          }
        ]
      )
      cfg
    // mapAttrs'
      (
        name: cfg:
        nameValuePair "${name}-offsite" (
          mkMerge [
            (removeAttrs cfg [ "repositoryName" ])
            {
              repository = "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${cfg.repositoryName}";
              environmentFile = offsiteEnvPath;
              initialize = true;
            }
          ]
        )
      )
      cfg;

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
