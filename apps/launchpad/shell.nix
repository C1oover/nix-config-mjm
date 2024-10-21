let
  sources = import ../../npins;
  pkgs = import sources.nixos-small { };
  devshell = import sources.devshell { nixpkgs = pkgs; };
in
devshell.mkShell (
  {
    lib,
    pkgs,
    extraModulesPath,
    ...
  }:
  let
    inherit (lib) attrValues nameValuePair;

    nameEvalPair = name: eval: { inherit name eval; };

  in
  {
    imports = [
      "${extraModulesPath}/services/postgres.nix"
      "${extraModulesPath}/language/c.nix"
      "${extraModulesPath}/language/rust.nix"
    ];

    language.c.includes = attrValues {
      inherit (pkgs) openssl;
    };

    services.postgres = {
      package = pkgs.postgresql_16;
    };

    devshell.packages = attrValues {
      inherit (pkgs)
        cargo-watch
        rust-analyzer

        just
        sqlx-cli
        systemfd
        ;
    };

    env = [
      (nameEvalPair "SECRETS_DIR" "$PRJ_DATA_DIR/secrets")
      (nameEvalPair "LAUNCHPAD_PAPERLESS_TOKEN_FILE" "$SECRETS_DIR/paperless_token")
      (nameEvalPair "LAUNCHPAD_GITLAB_TOKEN_FILE" "$SECRETS_DIR/gitlab_token")
      (nameEvalPair "LAUNCHPAD_REMINDERS_TOPIC_FILE" "$SECRETS_DIR/reminders_topic")

      (nameEvalPair "DATABASE_URL" "postgresql:///$USER?host=$PGHOST")
      (nameEvalPair "LAUNCHPAD_DATABASE_URL" "$DATABASE_URL")

      (nameValuePair "OTEL_SERVICE_NAME" "launchpad")
      (nameValuePair "OTEL_RESOURCE_ATTRIBUTES" "deployment.environment.name=dev")
      (nameValuePair "OTEL_EXPORTER_OTLP_ENDPOINT" "http://tempo.service.consul:14317")
    ];

    devshell.startup.secrets.text = ''
      mkdir -p $SECRETS_DIR
    '';
  }
)
