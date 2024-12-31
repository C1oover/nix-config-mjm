{
  config,
  lib,
  localModulesPath,
  ...
}:
let
  inherit (lib)
    mkOption
    optional
    types
    ;

  username = config.mjm.username;
in
{
  options.mjm.username = mkOption {
    type = types.str;
    default = "matt";
  };

  config = {
    home-manager.users.${username}.imports =
      let
        machineSpecificConfig = ../../../home/matt/${config.networking.hostName}.nix;
      in
      [
        "${localModulesPath}/home-manager"
      ]
      ++ optional (builtins.pathExists machineSpecificConfig) machineSpecificConfig;
  };
}
