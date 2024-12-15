let
  sources = import ../../npins;
  pkgs = import sources.nixos-small { config.allowUnfree = true; };
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
      ../../modules/devshell/vault-secrets.nix
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

        graphql-client
        just
        sqlx-cli
        systemfd
        ;
    };

    vault-secrets.services.launchpad.keys = {
      paperless_token.envVarName = "LAUNCHPAD_PAPERLESS_TOKEN_FILE";
      netbox_token.envVarName = "LAUNCHPAD_NETBOX_TOKEN_FILE";
      gitlab_token.envVarName = "LAUNCHPAD_GITLAB_TOKEN_FILE";
    };

    env = [
      (nameEvalPair "LAUNCHPAD_REMINDERS_TOPIC_FILE" "$SECRETS_DIR/reminders_topic")

      (nameEvalPair "DATABASE_URL" "postgresql:///$USER?host=$PGHOST")
      (nameEvalPair "LAUNCHPAD_DATABASE_URL" "$DATABASE_URL")

      (nameValuePair "OTEL_SERVICE_NAME" "launchpad")
      (nameValuePair "OTEL_RESOURCE_ATTRIBUTES" "deployment.environment.name=dev")
      (nameValuePair "OTEL_EXPORTER_OTLP_ENDPOINT" "http://tempo.service.consul:14317")
    ];
  }
)
