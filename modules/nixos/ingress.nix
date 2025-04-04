{ pkgs, lib, ... }:
let
  inherit (lib) mkOption types;

  jsonFormat = pkgs.formats.json { };

  vhostType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        upstream = {
          name = mkOption {
            type = types.str;
            default = name;
          };
          ipHash = mkOption {
            type = types.bool;
            default = false;
          };
          tls = {
            enable = mkOption {
              type = types.bool;
              default = false;
            };
          };
          service = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            port = mkOption {
              type = types.nullOr types.port;
              default = null;
            };
            tag = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        };
        enableAuthProxy = mkOption {
          type = types.bool;
          default = true;
        };
        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        extraRoutes = mkOption {
          type = types.listOf (types.submodule { freeformType = jsonFormat.type; });
          default = [ ];
        };
        useIPv4Proxy = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };
in
{
  options.ingress = {
    virtualHosts = mkOption {
      default = { };
      type = types.attrsOf (types.submodule vhostType);
    };
  };
}
