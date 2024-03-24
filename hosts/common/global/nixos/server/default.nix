{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = [
    ./gc.nix
    ./node-exporter.nix
    ./promtail.nix
  ];

  options.mjm.server = {
    enable = mkEnableOption "server setup";

    enableGarbageCollection = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable automatic nightly garbage collection";
    };

    enablePromtail = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable shipping logs to Loki with Promtail";
    };

    enableNodeExporter = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the Prometheus node-exporter";
    };
  };
}
