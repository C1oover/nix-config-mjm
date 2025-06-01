{
  config,
  lib,
  localModulesPath,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optional
    pathExists
    types
    ;

  username = config.cloover.username;
  machineSpecificConfig = ../../../hosts/${config.networking.hostName}/home.nix;
in
{
  options.cloover.username = mkOption {
    type = types.str;
    default = "matt";
  };

  config = mkIf (!config.cloover.minimal.enable) {
    home-manager.users.${username}.imports = [
      "${localModulesPath}/home-manager"
    ] ++ optional (pathExists machineSpecificConfig) machineSpecificConfig;
  };
}
