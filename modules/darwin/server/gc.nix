{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.mjm.server;
in
{
  options.mjm.server.enableGarbageCollection = mkOption {
    type = types.bool;
    default = true;
    description = "Whether to enable automatic nightly garbage collection";
  };

  config = mkIf (cfg.enable && cfg.enableGarbageCollection) {
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };

    nix.settings = {
      min-free = 100 * 1024 * 1024;
      max-free = 2 * 1024 * 1024 * 1024;
    };
  };
}
