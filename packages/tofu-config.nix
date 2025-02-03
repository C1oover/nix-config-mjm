{
  lib,
  pkgs,
}:

let
  nodes = (import ../plans.nix { }).hosts;

  config = lib.evalModules {
    modules = [
      { _module.args = { inherit pkgs nodes; }; }
      ../modules/tofu
    ];
    specialArgs.inputs = import ../npins/patched.nix;
  };
in
config.config.tofuConfig.json
