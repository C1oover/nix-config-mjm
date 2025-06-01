{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  inherit (lib)
    attrValues
    concatStringsSep
    getExe
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkIf
    mkOption
    nameValuePair
    optional
    optionalString
    pipe
    types
    ;

  trustDomain = config.cloover.spire.agent.trustDomain;
in
{
  options.cloover.backups = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            inherit (options.services.restic.backups.type.getSubOptions [ ])
              paths
              exclude
              user
              ;

            repositoryName = mkOption {
              type = types.str;
              default = name;
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
        }
      )
    );
  };

  config = mkIf (config.cloover.backups != { }) {
    environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

    cloover.garage.clients.backups = { };

    # can't use cloover.services, as it introduces an infinite recursion, so doing this manually
    cloover.spire.entries = {
      "backups-${config.networking.hostName}" = {
        spiffe_id = "spiffe://${trustDomain}/svc/backups";
        parent_id = "spiffe://${trustDomain}/${config.networking.hostName}";
      };
      spiffe-creds-backups = {
        spiffe_id = "spiffe://${trustDomain}/svc/backups";
        selectors = [
          {
            type = "systemd";
            value = "id:spiffe-creds@backups.service";
          }
        ];
      };
    };
    vault.services.backups = { };
    systemd.sockets."spiffe-creds@backups" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "sockets.target" ];
    };

    cloover.state.directories = pipe config.cloover.backups [
      (mapAttrs (
        name: cfg: {
          directory = "/var/cache/restic-backups-${name}";
          user = cfg.user;
        }
      ))
      attrValues
    ];

    systemd.services = mapAttrs' (
      name: cfg:
      let
        resticCmd = getExe pkgs.restic;
        excludeFlags = optionalString (
          cfg.exclude != [ ]
        ) "--exclude-file=${pkgs.writeText "exclude-patterns" (concatStringsSep "\n" cfg.exclude)}";
        includePaths = pkgs.writeText "include-patterns" (concatStringsSep "\n" cfg.paths);
        onsiteRepository = "s3:http://localhost:3902/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/cloover-restic-backups/${cfg.repositoryName}";
        mkPreamble = repo: location: ''
          set -e
          set -o pipefail

          export RESTIC_REPOSITORY="${repo}"
          ${optionalString (location == "onsite") ''
            export AWS_DEFAULT_REGION=home
            export AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=/creds
          ''}
          ${optionalString (location == "offsite") ''
            export AWS_ACCESS_KEY_ID="$(cat $CREDENTIALS_DIRECTORY/backups_b2_key_id)"
            export AWS_SECRET_ACCESS_KEY="$(cat $CREDENTIALS_DIRECTORY/backups_b2_application_key)"
          ''}
        '';
        mkExecStart =
          repo: location:
          pkgs.writeShellScript "backup-exec-start" ''
            ${mkPreamble repo location}

            ${resticCmd} unlock
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
        description = "Daily Restic Backup '${name}'";
        environment = {
          RESTIC_CACHE_DIR = "/var/cache/restic-backups-${name}";
          RESTIC_PASSWORD_FILE = "%d/${name}_backup_password";
        };
        path = [ config.programs.ssh.package ];
        restartIfChanged = false;
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        startLimitBurst = 4;
        startLimitIntervalSec = 600;
        credentials = {
          backups.b2_key_id = { };
          backups.b2_application_key = { };
          ${name}.backup_password = { };
        };
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
          Restart = "on-failure";
          RestartSec = "2m";
        };
      }
    ) config.cloover.backups;

    systemd.timers = mapAttrs' (
      name: cfg:
      nameValuePair "restic-backups-${name}" {
        description = "Daily Restic Backup '${name}'";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "2h";
        };
      }
    ) config.cloover.backups;

    environment.systemPackages = mapAttrsToList (
      name: cfg:
      let
        resticCmd = getExe pkgs.restic;
        onsiteRepository = "s3:http://localhost:3902/restic-backups/${cfg.repositoryName}";
        offsiteRepository = "s3:s3.us-west-001.backblazeb2.com/cloover-restic-backups/${cfg.repositoryName}";

        innerScript = pkgs.writeShellScript "restic-${name}-inner" ''
          if [ "$BACKUP_KIND" = onsite ]; then
            export AWS_DEFAULT_REGION=home
            export AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=/creds
          elif [ "$BACKUP_KIND" = offsite ]; then
            export AWS_ACCESS_KEY_ID="$(cat $CREDENTIALS_DIRECTORY/backups_b2_key_id)"
            export AWS_SECRET_ACCESS_KEY="$(cat $CREDENTIALS_DIRECTORY/backups_b2_application_key)"
          fi
          export RESTIC_PASSWORD_FILE=$CREDENTIALS_DIRECTORY/${name}_backup_password

          exec ${resticCmd} "$@"
        '';
      in
      pkgs.writeShellScriptBin "restic-${name}" ''
        kind="$1"
        shift

        if [ "$kind" = onsite ]; then
          export RESTIC_REPOSITORY="${onsiteRepository}"
        elif [ "$kind" = offsite ]; then
          export RESTIC_REPOSITORY="${offsiteRepository}"
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
        exec ${pkgs.systemd}/bin/systemd-run \
          --service-type=oneshot \
          --wait -qt --collect \
          -p User=${cfg.user} \
          -p LoadCredential=backups_b2_key_id:/run/backups-creds.sock \
          -p LoadCredential=backups_b2_application_key:/run/backups-creds.sock \
          -p LoadCredential=${name}_backup_password:/run/${name}-creds.sock \
          -E BACKUP_KIND=$kind \
          -E RESTIC_REPOSITORY -E RESTIC_CACHE_DIR -E PATH \
           ${innerScript} "$@"
      ''
    ) config.cloover.backups;
  };
}
