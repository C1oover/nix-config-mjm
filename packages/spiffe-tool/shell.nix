{
  sources ? import ../../npins,
  pkgs ? import sources.nixos-small {
    config.allowUnfree = true;
    overlays = [ (import ../../overlay.nix) ];
  },
  devshell ? import sources.devshell { nixpkgs = pkgs; },
}:

devshell.mkShell (
  { pkgs, lib, ... }:
  let
    inherit (lib) attrValues nameValuePair;
  in
  {
    imports = [
      ../../modules/devshell/vault-secrets.nix
    ];

    packages = attrValues {
      inherit (pkgs)
        go
        gopls
        systemfd
        ;
    };

    vault-secrets.services = {
      spiffe-users.keys = {
        dev_oidc_client_secret.envVarName = "SPIFFE_USERS_OIDC_CLIENT_SECRET_FILE";
      };
      garage.keys.admin_token = { };
    };

    env = [
      {
        name = "CREDENTIALS_DIRECTORY";
        eval = "$SECRETS_DIR";
      }

      (nameValuePair "SPIFFE_USERS_TRUST_DOMAIN" "spiffe://dev.users.midna.dev")
      (nameValuePair "SPIFFE_USERS_OIDC_PROVIDER_URL" "https://auth.midna.dev")
      (nameValuePair "SPIFFE_USERS_OIDC_CLIENT_ID" "KgTTscl9NQvJwVms9Kaa0QTVGs3OwPM0zAdCjUMtB84jQo1U31uN1a2oab84W3u7")

      (nameValuePair "OTEL_RESOURCE_ATTRIBUTES" "deployment.environment.name=dev")
      (nameValuePair "OTEL_EXPORTER_OTLP_ENDPOINT" "http://tempo.service.consul:14318")
    ];
  }
)
