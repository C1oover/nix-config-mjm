{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;

  trustDomain = config.cloover.spire.agent.trustDomain;

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
  options.cloover.spire.entries = mkOption {
    default = [ ];
    type = types.attrsOf entryType;
  };

  config = {
    cloover.spire.entries = { };
  };
}
