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
      repositoryName = "postgresql";
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
    text = ''
      {{ with secret "kv/postgresql" }}{{ .Data.data.backup_password }}{{ end }}
    '';
    owner = "postgres";
  };
}
