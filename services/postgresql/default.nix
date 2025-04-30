{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStrings
    mkEnableOption
    mkIf
    pipe
    unique
    ;

  cfg = config.mjm.postgresql;
in
{
  options.mjm.postgresql = {
    enable = mkEnableOption "postgresql";
  };

  config = mkIf cfg.enable {
    deployment.tags = [ "svc-postgresql" ];
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
        dumpDBs = pipe config.services.postgresql.ensureDatabases [
          unique
          (concatMapStrings (dbname: ''
            ${pg}/bin/pg_dump --format=directory -j 4 -f ${dbname} ${dbname}
          ''))
        ];
      in
      {
        paths = [ "/tmp/pgbackup" ];
        user = "postgres";
        backupPrepareCommand = ''
          set -x
          mkdir /tmp/pgbackup
          cd /tmp/pgbackup
          ${pg}/bin/pg_dumpall --globals-only -f /tmp/pgbackup/globals.sql
          ${dumpDBs}
        '';
        backupCleanupCommand = ''
          rm -rf /tmp/pgbackup
        '';
      };

    vault.services.postgresql = { };
    systemd.sockets."spiffe-creds@postgresql" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "sockets.target" ];
    };

    deployment.tests = mkIf pkgs.stdenv.isx86_64 {
      inherit (pkgs.nixosTests.postgresql.postgresql.postgresql_16)
        postgresql
        postgresql-backup-all
        ;
    };
  };
}
