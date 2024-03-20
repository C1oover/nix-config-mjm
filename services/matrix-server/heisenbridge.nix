{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.matrix-server;
in
{
  options.mjm.matrix-server.bridges.irc = {
    enable = mkEnableOption "IRC bridge" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.bridges.irc.enable) {
    mjm.state.directories = [ "/var/lib/heisenbridge" ];

    services.heisenbridge = {
      enable = true;
      homeserver = "http://localhost:6167";
      debug = true;
      owner = "@mjm:midna.dev";
      namespaces = {
        users = [
          {
            regex = "@irc_.*";
            exclusive = true;
          }
        ];
        aliases = [ ];
        rooms = [ ];
      };
    };
  };
}
