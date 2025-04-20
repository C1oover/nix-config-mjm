{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = [
    ./alloy.nix
    ./gc.nix
    ./ssh-cert.nix
  ];

  options.mjm.server = {
    enable = mkEnableOption "server setup";

    enableGarbageCollection = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable automatic nightly garbage collection";
    };

    enableAlloy = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Alloy for collecting logs and metrics";
    };

    enableSSHHostCert = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to generate and configure an SSH host certificate";
    };
  };
}
