{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options = {
    terraform = mkOption {
      default = { };
      type = types.submoduleWith {
        description = "Terraform module";
        modules = [
          "${inputs.terranix}/core/terraform-options.nix"
          "${inputs.terranix}/modules"
          { _module.args.pkgs = pkgs; }
        ];
      };
    };
  };
}
