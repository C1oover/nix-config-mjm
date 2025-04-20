{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.services.invidious = {
      postgresql.enable = true;
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    ingress.virtualHosts.yt = {
      upstream.service.name = "invidious";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.invidious = {
      enable = true;
      domain = "yt.midna.dev";
      address = "::";
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
      extraSettingsFile = "/run/credentials/invidious.service/invidious_extra_settings";

      sig-helper.enable = true;
    };

    systemd.services.invidious = {
      serviceConfig.LoadCredential = [ "invidious_extra_settings:/run/invidious-creds.sock" ];
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
