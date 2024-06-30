{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.services.media-server.vault.keys.sabnzbd_api_key = { };
    mjm.state.directories = [
      {
        directory = "/var/lib/sabnzbd";
        inherit (config.services.sabnzbd) user group;
      }
    ];

    vault-secrets.wantedBy = [ "prometheus-sabnzbd-exporter.service" ];

    ingress.virtualHosts.downloads = {
      upstream.service.name = "sabnzbd";
    };

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
          apiKeyFile = config.mjm.services.media-server.vault.keys.sabnzbd_api_key.path;
        }
      ];
    };

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

    mjm.backups.mediaserver.paths = [
      "/var/lib/sabnzbd/admin"
      "/var/lib/sabnzbd/sabnzbd.ini"
    ];
  };
}
