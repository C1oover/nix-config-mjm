{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.postgresql;
in
{
  options.mjm.postgresql = {
    enable = mkEnableOption "postgresql";
  };

  config = mkIf cfg.enable {
    mjm.services.postgresql = { };
    mjm.state.directories = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "0750";
      }
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };

    mjm.backups.postgresql =
      let
        pg = config.services.postgresql.package;
      in
      {
        passwordFile = config.vault-secrets.services.postgresql.keys.backup_password.path;
        paths = [ "/tmp/pgbackup" ];
        user = "postgres";
        backupPrepareCommand = ''
          set -x
          mkdir /tmp/pgbackup
          cd /tmp/pgbackup
          ${pg}/bin/pg_dumpall --globals-only -f /tmp/pgbackup/globals.sql
          ${lib.concatMapStrings (dbname: ''
            ${pg}/bin/pg_dump --format=directory -j 4 -f ${dbname} ${dbname}
          '') config.services.postgresql.ensureDatabases}
        '';
        backupCleanupCommand = ''
          rm -rf /tmp/pgbackup
        '';
      };

    vault.services.postgresql = { };
    vault-secrets.services.postgresql = {
      keys.backup_password = {
        owner = "postgres";
      };
    };
  };
}
