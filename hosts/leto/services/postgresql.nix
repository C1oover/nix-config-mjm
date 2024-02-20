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

  mjm.backups.postgresql =
    let
      pg = config.services.postgresql.package;
    in
    {
      passwordFile = config.vault-secrets.templates.postgresql-backup-password.path;
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
    };

  vault-secrets.templates.postgresql-backup-password = {
    kvPath = "kv/postgresql/backup_password";
    owner = "postgres";
  };
}
