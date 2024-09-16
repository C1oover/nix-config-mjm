let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos-small { },
}:

let
  postgres = pkgs.postgresql_16;
  pkg = import ./default.nix { inherit pkgs; };
in

pkgs.mkShell {
  inputsFrom = [ pkg ];
  packages = builtins.attrValues {
    inherit (pkgs)
      cargo
      cargo-watch
      rustc
      rust-analyzer
      rustfmt

      postgresql_16
      sqlx-cli
      just
      ;

    pg = pkgs.writers.writeNuBin "pg" ''
      def "main start" [] {
        mkdir $env.PGHOST
        if ($env.PGDATA | path type) != "dir" {
          ${postgres}/bin/initdb
        }

        cp -f ${pkgs.writeText "postgresql.conf" ''
          listen_addresses = '''
          port = 5432
          unix_socket_directories = '__PWD__/.pg/host'
        ''} ($env.PGDATA | path join postgresql.conf)
        sed -i -e $'s$__PWD__$($env.PWD)$' ($env.PGDATA | path join postgresql.conf)

        exec ${postgres}/bin/postgres
      }

      def "main create" [] {
        'create database "launchpad_dev";' | ${postgres}/bin/psql --dbname postgres
      }

      def main [] {}
    '';
  };

  shellHook = ''
    mkdir -p .secrets
    export LAUNCHPAD_PAPERLESS_TOKEN_FILE=".secrets/paperless_token"
    export LAUNCHPAD_GITLAB_TOKEN_FILE=".secrets/gitlab_token"

    mkdir -p .pg
    export PGDATA="$PWD/.pg/data"
    export PGHOST="$PWD/.pg/host"
    export PGPORT="5432"
    export DATABASE_URL="postgresql:///launchpad_dev?host=$PGHOST"
    export LAUNCHPAD_DATABASE_URL="$DATABASE_URL"

    export OTEL_SERVICE_NAME="launchpad"
    export OTEL_RESOURCE_ATTRIBUTES="deployment.environment.name=dev"
    export OTEL_EXPORTER_OTLP_ENDPOINT="http://tempo.service.consul:14317"
  '';
}
