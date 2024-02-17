{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [ ../../common/optional/backup.nix ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
  };

  services.restic.backups.postgresql =
    let
      pg = config.services.postgresql.package;
    in
    {
      initialize = true;
      repository = "s3:http://garage.service.consul:3902/restic-backups/postgresql";
      passwordFile = config.vault-secrets.templates.postgresql-backup-password.path;
      environmentFile = config.vault-secrets.templates.restic-backup-env.path;
      paths = [ "/tmp/pgbackup" ];
      user = "postgres";
      backupPrepareCommand = ''
        set -x
        mkdir /tmp/pgbackup
        cd /tmp/pgbackup
        ${pg}/bin/pg_dumpall --globals-only -f /tmp/pgbackup/globals.sql
        ${lib.concatMapStrings
          (dbname: ''
            ${pg}/bin/pg_dump --format=directory -j 4 -f ${dbname} ${dbname}
          '')
          config.services.postgresql.ensureDatabases}
      '';
      backupCleanupCommand = ''
        rm -rf /tmp/pgbackup
      '';
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
      ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "2h";
      };
    };

  vault-secrets.templates.postgresql-backup-password = {
    text = ''
      {{ with secret "kv/postgresql" }}{{ .Data.data.backup_password }}{{ end }}
    '';
    owner = "postgres";
  };
}
