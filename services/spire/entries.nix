{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;

  trustDomain = config.mjm.spire.agent.trustDomain;

  entryType = types.submodule (
    { config, ... }:
    {
      options = {
        spiffe_id = mkOption {
          # TODO make sure it and parent starts with spiffe://
          type = types.str;
        };
        parent_id = mkOption {
          type = types.str;
          default = config.spiffe_id;
        };
        selectors = mkOption {
          type = types.listOf selectorType;
          default = [
            {
              type = "spiffe_id";
              value = config.parent_id;
            }
          ];
        };
        dns_names = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
    }
  );

  selectorType = types.submodule {
    options = {
      type = mkOption { type = types.str; };
      value = mkOption { type = types.str; };
    };
  };
in
{
  options.mjm.spire.entries = mkOption {
    default = [ ];
    type = types.attrsOf entryType;
  };

  config = {
    # hardcode some entries for the single mac server
    mjm.spire.entries = {
      talos-consul = {
        spiffe_id = "spiffe://${trustDomain}/svc/consul-client";
        parent_id = "spiffe://${trustDomain}/talos";
        selectors = [
          {
            type = "unix";
            value = "user:consul";
          }
        ];
      };
      talos-mautrix-imessage = {
        spiffe_id = "spiffe://${trustDomain}/svc/mautrix-imessage";
        parent_id = "spiffe://${trustDomain}/talos";
        selectors = [
          {
            type = "unix";
            value = "user:mautrix-imessage";
          }
        ];
        dns_names = [ "mautrix-imessage.service.consul" ];
      };
    };
  };
}
