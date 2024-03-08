{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    getExe
    mapAttrs'
    mapAttrsToList
    mkIf
    mkOption
    nameValuePair
    optional
    optionalString
    types
    ;

  topConfig = config;
in
{
  options.mjm.backups = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
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

            useVaultSecrets = mkOption {
              type = types.bool;
              default = true;
            };

            onsiteEnvPath = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };

            offsiteEnvPath = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };
          };

          config =
            let
              secrets =
                if config.useVaultSecrets then topConfig.vault-secrets.templates else topConfig.age.secrets;
            in
            {
              onsiteEnvPath = secrets.restic-backup-env.path;
              offsiteEnvPath = secrets.restic-backup-offsite-env.path;
            };
        }
      )
    );
  };

  config = mkIf (config.mjm.backups != { }) {
    systemd.services = mapAttrs' (
      name: cfg:
      let
        resticCmd = getExe pkgs.restic;
        excludeFlags = optionalString (
          cfg.exclude != [ ]
        ) "--exclude-file=${pkgs.writeText "exclude-patterns" (concatStringsSep "\n" cfg.exclude)}";
        includePaths = pkgs.writeText "include-patterns" (concatStringsSep "\n" cfg.paths);
        onsiteRepository = "s3:http://garage.service.consul:3902/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${cfg.repositoryName}";
        mkPreamble = repo: envFile: ''
          set -ae
          set -o pipefail

          RESTIC_REPOSITORY="${repo}"
          source $CREDENTIALS_DIRECTORY/${envFile}
        '';
        mkExecStart =
          repo: envFile:
          pkgs.writeShellScript "backup-exec-start" ''
            ${mkPreamble repo envFile}

            ${resticCmd} backup ${excludeFlags} --files-from=${includePaths}
            ${resticCmd} forget --prune --keep-weekly 4 --keep-daily 7
            ${resticCmd} check
          '';

        mkExecStartPre =
          repo: envFile:
          pkgs.writeShellScript "backup-exec-start-pre" ''
            ${mkPreamble repo envFile}

            ${resticCmd} snapshots || ${resticCmd} init
          '';
      in
      nameValuePair "restic-backups-${name}" {
        environment = {
          RESTIC_CACHE_DIR = "/var/cache/restic-backups-${name}";
          RESTIC_PASSWORD_FILE = cfg.passwordFile;
        };
        path = [ config.programs.ssh.package ];
        restartIfChanged = false;
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = [
            "${mkExecStart onsiteRepository "onsite-env"}"
            "${mkExecStart offsiteRepository "offsite-env"}"
          ];
          ExecStartPre =
            optional (
              cfg.backupPrepareCommand != null
            ) "${pkgs.writeShellScript "backup-prepare-command" cfg.backupPrepareCommand}"
            ++ [
              "${mkExecStartPre onsiteRepository "onsite-env"}"
              "${mkExecStartPre offsiteRepository "offsite-env"}"
            ];
          ExecStopPost = optional (
            cfg.backupCleanupCommand != null
          ) "${pkgs.writeShellScript "backup-cleanup-command" cfg.backupCleanupCommand}";
          User = cfg.user;
          RuntimeDirectory = "restic-backups-${name}";
          CacheDirectory = "restic-backups-${name}";
          CacheDirectoryMode = "0700";
          PrivateTmp = true;
          LoadCredential = [
            "onsite-env:${cfg.onsiteEnvPath}"
            "offsite-env:${cfg.offsiteEnvPath}"
          ];
        };
      }
    ) config.mjm.backups;

    systemd.timers = mapAttrs' (
      name: cfg:
      nameValuePair "restic-backups-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "2h";
        };
      }
    ) config.mjm.backups;

    environment.systemPackages = mapAttrsToList (
      name: cfg:
      let
        resticCmd = getExe pkgs.restic;
        onsiteRepository = "s3:http://garage.service.consul:3902/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${cfg.repositoryName}";
      in
      pkgs.writeShellScriptBin "restic-${name}" ''
        set -a

        kind="$1"
        shift

        if [ "$kind" = onsite ]; then
          RESTIC_REPOSITORY="${onsiteRepository}"
          source ${cfg.onsiteEnvPath}
        elif [ "$kind" = offsite ]; then
          RESTIC_REPOSITORY="${offsiteRepository}"
          source ${cfg.offsiteEnvPath}
        else
          echo "first argument must be 'onsite' or 'offsite'" >&2
          exit 1
        fi

        ${lib.pipe config.systemd.services."restic-backups-${name}".environment [
          (lib.filterAttrs (n: v: v != null && n != "PATH"))
          (lib.mapAttrsToList (n: v: "${n}=${v}"))
          (lib.concatStringsSep "\n")
        ]}
        PATH=${config.systemd.services."restic-backups-${name}".environment.PATH}:$PATH

        exec ${resticCmd} "$@"
      ''
    ) config.mjm.backups;

    vault-secrets.templates =
      mkIf (builtins.any (cfg: cfg.useVaultSecrets) (builtins.attrValues config.mjm.backups))
        {
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

    age.secrets =
      mkIf (builtins.any (cfg: !cfg.useVaultSecrets) (builtins.attrValues config.mjm.backups))
        {
          restic-backup-env.file = ../../../secrets/restic-backup-env.age;
          restic-backup-offsite-env.file = ../../../secrets/restic-backup-offsite-env.age;
        };
  };
}
