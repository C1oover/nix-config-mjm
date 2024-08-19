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
          addresses = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };
          ipHash = mkOption {
            type = types.bool;
            default = false;
          };
          useSSL = mkOption {
            type = types.bool;
            default = false;
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
          type = types.listOf (types.submodule ({ freeformType = jsonFormat.type; }));
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
