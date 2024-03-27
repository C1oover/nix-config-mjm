{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.state.directories = [
      {
        directory = "/var/lib/sabnzbd";
        inherit (config.services.sabnzbd) user group;
      }
    ];

    services.sabnzbd = {
      enable = true;
    };

    users.users.sabnzbd.extraGroups = [ "media" ];

    services.prometheus.exporters.sabnzbd = {
      enable = true;
      openFirewall = true;
      listenAddress = "::";
      servers = [
        {
          baseUrl = "http://localhost:8080/sabnzbd";
          apiKeyFile = config.vault-secrets.services.media-server.keys.sabnzbd_api_key.path;
        }
      ];
    };

    vault-secrets.wantedBy = [ "prometheus-sabnzbd-exporter.service" ];
    vault-secrets.services.media-server.keys.sabnzbd_api_key = { };

    networking.firewall.allowedTCPPorts = [ 8080 ];

    services.consul.services.sabnzbd = {
      port = 8080;

      meta = {
        metrics_path = "/metrics";
        metrics_port = toString config.services.prometheus.exporters.sabnzbd.port;
      };

      checks = [
        {
          name = "sabnzbd is ready";
          http = "http://localhost:8080/";
          interval = "15s";
          timeout = "10s";
          failures_before_warning = 2;
          failures_before_critical = 6;
        }
      ];
    };
  };
}
