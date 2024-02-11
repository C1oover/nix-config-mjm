{
  pkgs,
  config,
  lib,
  ...
}:
{
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
      passwordFile = config.age.secrets."postgresql-backup-password".path;
      environmentFile = config.age.secrets."backup.env".path;
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

  age.secrets."backup.env".file = ../../../secrets/restic-backup-env.age;
  age.secrets."postgresql-backup-password" = {
    file = ../../../secrets/postgresql-backup-password.age;
    owner = "postgres";
  };
}
