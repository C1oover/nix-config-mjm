{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    services.invidious = {
      enable = true;
      domain = "tube.midna.dev";
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.invidious.port ];

    services.consul.services.invidious = {
      inherit (config.services.invidious) port;

      checks = [
        {
          name = "invidious is ready";
          http = "http://localhost:${toString config.services.invidious.port}/";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };
  };
}
