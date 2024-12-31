{
  config,
  lib,
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
        ../../../home/matt/global
      ]
      ++ optional (builtins.pathExists machineSpecificConfig) machineSpecificConfig;
  };
}
