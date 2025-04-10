{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  inherit (lib)
    attrNames
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

  backupKeys = config.vault-secrets.common.backups.keys;
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
              ;

            repositoryName = mkOption {
              type = types.str;
              default = name;
            };

            onsiteKeyIdFile = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };

            onsiteSecretKeyFile = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };

            offsiteKeyIdFile = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };

            offsiteSecretKeyFile = mkOption {
              type = types.path;
              readOnly = true;
              internal = true;
            };

            backupPrepareCommand = mkOption {
              type = types.nullOr types.lines;
              default = null;
            };

            backupCleanupCommand = mkOption {
              type = types.nullOr types.lines;
              default = null;
            };
          };

          config = {
            onsiteKeyIdFile = backupKeys.garage_key_id.path;
            onsiteSecretKeyFile = backupKeys.garage_secret_key.path;
            offsiteKeyIdFile = backupKeys.b2_key_id.path;
            offsiteSecretKeyFile = backupKeys.b2_application_key.path;
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
        onsiteRepository = "s3:garage.midna.dev/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${cfg.repositoryName}";
        mkPreamble = repo: location: ''
          set -e
          set -o pipefail

          export RESTIC_REPOSITORY="${repo}"
          ${optionalString (location == "onsite") "export AWS_DEFAULT_REGION=home"}
          export AWS_ACCESS_KEY_ID="$(cat $CREDENTIALS_DIRECTORY/${location}-key-id)"
          export AWS_SECRET_ACCESS_KEY="$(cat $CREDENTIALS_DIRECTORY/${location}-secret-key)"
        '';
        mkExecStart =
          repo: location:
          pkgs.writeShellScript "backup-exec-start" ''
            ${mkPreamble repo location}

            ${resticCmd} backup ${excludeFlags} --files-from=${includePaths}
            ${resticCmd} forget --prune --keep-weekly 4 --keep-daily 7
            ${resticCmd} check
          '';

        mkExecStartPre =
          repo: location:
          pkgs.writeShellScript "backup-exec-start-pre" ''
            ${mkPreamble repo location}

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
            "${mkExecStart onsiteRepository "onsite"}"
            "${mkExecStart offsiteRepository "offsite"}"
          ];
          ExecStartPre =
            optional (
              cfg.backupPrepareCommand != null
            ) "${pkgs.writeShellScript "backup-prepare-command" cfg.backupPrepareCommand}"
            ++ [
              "${mkExecStartPre onsiteRepository "onsite"}"
              "${mkExecStartPre offsiteRepository "offsite"}"
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
            "onsite-key-id:${cfg.onsiteKeyIdFile}"
            "onsite-secret-key:${cfg.onsiteSecretKeyFile}"
            "offsite-key-id:${cfg.offsiteKeyIdFile}"
            "offsite-secret-key:${cfg.offsiteSecretKeyFile}"
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
        onsiteRepository = "s3:garage.midna.dev/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups/${cfg.repositoryName}";
      in
      pkgs.writeShellScriptBin "restic-${name}" ''
        kind="$1"
        shift

        if [ "$kind" = onsite ]; then
          export RESTIC_REPOSITORY="${onsiteRepository}"
          export AWS_DEFAULT_REGION=home
          export AWS_ACCESS_KEY_ID="$(cat ${cfg.onsiteKeyIdFile})"
          export AWS_SECRET_ACCESS_KEY="$(cat ${cfg.onsiteSecretKeyFile})"
        elif [ "$kind" = offsite ]; then
          export RESTIC_REPOSITORY="${offsiteRepository}"
          export AWS_ACCESS_KEY_ID="$(cat ${cfg.offsiteKeyIdFile})"
          export AWS_SECRET_ACCESS_KEY="$(cat ${cfg.offsiteSecretKeyFile})"
        else
          echo "first argument must be 'onsite' or 'offsite'" >&2
          exit 1
        fi

        ${lib.pipe config.systemd.services."restic-backups-${name}".environment [
          (lib.filterAttrs (n: v: v != null && n != "PATH"))
          (lib.mapAttrsToList (n: v: "export ${n}=${v}"))
          (lib.concatStringsSep "\n")
        ]}
        export PATH=${config.systemd.services."restic-backups-${name}".environment.PATH}:$PATH

        exec ${resticCmd} "$@"
      ''
    ) config.mjm.backups;

    vault.policies.common-backups = {
      paths."kv/data/prod/common/backups".capabilities = [ "read" ];
    };
    vault-secrets.wantedBy = map (name: "restic-backups-${name}.service") (
      attrNames config.mjm.backups
    );
    vault-secrets.common.backups.keys = {
      garage_key_id = { };
      garage_secret_key = { };
      b2_key_id = { };
      b2_application_key = { };
    };
  };
}
