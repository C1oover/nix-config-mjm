{
config,
  lib,
  nodes,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    mergeAttrsList
    mkIf
    mkMerge
    mkOption
    pipe
    types
    ;
  cfg = config.mjm.authelia;
  clients = pipe nodes [
    attrValues
    (map (n: n.config.mjm.authelia.oidcClients))
    mergeAttrsList
    attrValues
    (map (c: c.clientConfig))
  ];
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.mjm.authelia.oidcClients = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            name = mkOption { type = types.str; };
            clientId = mkOption { type = types.str; };
            clientSecret = mkOption { type = types.str; };

            requirePkce = mkOption {
              default = false;
              type = types.bool;
            };
            redirectUris = mkOption { type = types.listOf types.str; };
            scopes = mkOption {
              type = types.listOf types.str;
              default = [
                "openid"
                "profile"
                "groups"
                "email"
              ];
            };
            tokenEndpointAuthMethod = mkOption {
              default = "client_secret_basic";
              type = types.enum [
                "none"
                "client_secret_basic"
                "client_secret_post"
                "client_secret_jwt"
                "private_key_jwt"
              ];
            };

            clientConfig = mkOption {
              internal = true;
              type = types.submodule { freeformType = yamlFormat.type; };
            };
          };

          config.clientConfig = mkMerge [
            {
              client_id = config.clientId;
              client_name = config.name;
              client_secret = config.clientSecret;
              redirect_uris = config.redirectUris;
              scopes = config.scopes;
              token_endpoint_auth_method = config.tokenEndpointAuthMethod;
            }
            (mkIf config.requirePkce {
              require_pkce = true;
              pkce_challenge_method = "S256";
            })
          ];
        }
      )
    );
  };

  config = mkIf cfg.enable {
    services.authelia.instances.main.settings.identity_providers.oidc.clients = clients;
  };
}
