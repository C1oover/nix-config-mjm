{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.cloover.matrix-server;
in
{
  options.cloover.matrix-server.bridges.irc = {
    enable = mkEnableOption "IRC bridge" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.bridges.irc.enable) {
    cloover.state.directories = [ "/var/lib/heisenbridge" ];

    services.heisenbridge = {
      enable = true;
      homeserver = "http://localhost:6166";
      debug = true;
      owner = "@cloover:midna.dev";
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
