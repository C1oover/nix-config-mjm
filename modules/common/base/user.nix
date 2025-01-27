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
    pathExists
    types
    ;

  username = config.mjm.username;
  machineSpecificConfig = ../../../hosts/${config.networking.hostName}/home.nix;
in
{
  options.mjm.username = mkOption {
    type = types.str;
    default = "matt";
  };

  config = {
    home-manager.users.${username}.imports = [
      "${localModulesPath}/home-manager"
    ] ++ optional (pathExists machineSpecificConfig) machineSpecificConfig;
  };
}
