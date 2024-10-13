{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    ingress.virtualHosts.yt = {
      upstream.service.name = "invidious";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.invidious = {
      enable = true;
      domain = "yt.midna.dev";
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.invidious.port ];

    services.consul.services.invidious = {
      inherit (config.services.invidious) port;

      checks.up = {
        http.path = "/";
      };
    };
  };
}
