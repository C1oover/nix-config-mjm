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
    mkOption
    mkOverride
    pipe
    types
    unique
    ;

  cfg = config.mjm.postgresql;
  trustDomain = config.mjm.spire.agent.trustDomain;
in
{
  options.mjm.postgresql = {
    enable = mkEnableOption "postgresql";
    extraBackupDatabases = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
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
      package = mkOverride 900 pkgs.postgresql_16;
    };

    mjm.backups.postgresql =
      let
        pg = config.services.postgresql.package;
        dumpDBs = pipe (config.services.postgresql.ensureDatabases ++ cfg.extraBackupDatabases) [
          unique
          (concatMapStrings (dbname: ''
            ${pg}/bin/pg_dump --format=directory -j 4 -f ${dbname} ${dbname}
          ''))
        ];
      in
      {
        paths = [ "/var/lib/postgresql/backup" ];
        user = "postgres";
        backupPrepareCommand = ''
          set -x

          # in case the cleanup didn't happen for some reason
          rm -rf /var/lib/postgresql/backup
          mkdir -p /var/lib/postgresql/backup
          cd /var/lib/postgresql/backup

          ${pg}/bin/pg_dumpall --globals-only -f globals.sql
          ${dumpDBs}
        '';
        backupCleanupCommand = ''
          rm -rf /var/lib/postgresql/backup
        '';
      };

    # can't use mjm.services, as it introduces an infinite recursion, so doing this manually
    vault.services.postgresql = { };
    systemd.sockets."spiffe-creds@postgresql" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "sockets.target" ];
    };
    mjm.spire.entries = {
      "postgresql-${config.networking.hostName}" = {
        spiffe_id = "spiffe://${trustDomain}/svc/postgresql";
        parent_id = "spiffe://${trustDomain}/${config.networking.hostName}";
      };
      spiffe-creds-postgresql = {
        spiffe_id = "spiffe://${trustDomain}/svc/postgresql";
        selectors = [
          {
            type = "systemd";
            value = "id:spiffe-creds@postgresql.service";
          }
        ];
      };
    };

    deployment.tests = mkIf pkgs.stdenv.isx86_64 {
      inherit (pkgs.nixosTests.postgresql.postgresql.postgresql_16)
        postgresql
        postgresql-backup-all
        ;
    };
  };
}
