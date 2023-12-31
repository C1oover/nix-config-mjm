{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ingress;

  vhostType = with lib;
    {name, ...}: {
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
          path = mkOption {
            type = types.str;
            default = "";
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
            connectPort = mkOption {
              type = types.nullOr types.port;
              default = null;
            };
          };
        };
        external = mkOption {
          type = types.bool;
          default = false;
        };
        enableAuthProxy = mkOption {
          type = types.bool;
          default = true;
        };
        recommendedProxySettings = mkOption {
          type = types.bool;
          default = true;
        };
        proxyWebsockets = mkOption {
          type = types.bool;
          default = true;
        };
        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [];
        };
        extraServerConfig = mkOption {
          type = types.lines;
          default = "";
        };
        extraLocationConfig = mkOption {
          type = types.lines;
          default = "";
        };
      };
    };
in {
  options.ingress = {
    virtualHosts = mkOption {
      default = {};
      type = types.attrsOf (types.submodule vhostType);
    };
    extraTemplates = mkOption {
      default = {};
      type = types.attrs;
    };
  };
}
