{ pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;

  jsonFormat = pkgs.formats.json { };

  approleType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        tokenPolicies = mkOption {
          type = types.listOf types.str;
          default = [ name ];
        };
      };

      config.tokenPolicies = [ "common-host" ];
    };

  policyType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
        };
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
        };
        paths = mkOption {
          default = { };
          type = types.attrsOf jsonFormat.type;
        };
        approles = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };

  serviceType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        hosts = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        paths = mkOption {
          default = { };
          type = types.attrsOf jsonFormat.type;
        };
        commonPolicies = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };
in
{
  options.vault = {
    approles = {
      enable = mkEnableOption "vault's approle auth method";
      roles = mkOption {
        default = { };
        type = types.attrsOf (types.submodule approleType);
      };
    };
    policies = mkOption {
      type = types.attrsOf (types.submodule policyType);
      default = { };
    };
    services = mkOption {
      type = types.attrsOf (types.submodule serviceType);
      default = { };
    };
  };
}
