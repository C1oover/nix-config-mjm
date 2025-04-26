{ pkgs, lib, ... }:
let
  inherit (lib) mkOption types;

  jsonFormat = pkgs.formats.json { };

  serviceType =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        paths = mkOption {
          default = { };
          type = types.attrsOf jsonFormat.type;
        };
      };
    };
in
{
  options.vault = {
    services = mkOption {
      type = types.attrsOf (types.submodule serviceType);
      default = { };
    };
  };
}
