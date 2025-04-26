{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.services.sabnzbd = {
      vault = {
        enable = true;
      };
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/sabnzbd";
        inherit (config.services.sabnzbd) user group;
      }
    ];

    mjm.spire.creds.sabnzbd.aliases = {
      "prometheus-sabnzbd-exporter.service/apikey-0" = "sabnzbd/api_key";
    };

    ingress.virtualHosts.downloads = {
      upstream = {
        service.name = "sabnzbd";
        tls.enable = true;
      };
    };

    services.sabnzbd.enable = true;
    systemd.services.sabnzbd.networkNamespace = "sabnzbd";

    users.users.sabnzbd.extraGroups = [ "media" ];

    mjm.spire.tunnels = {
      sabnzbd = {
        mode = "server";
        listen.port = 8080;
        target.port = 8080;
        target.namespace = "sabnzbd";
        allowIngress = true;
        allowConsul = true;
        allowedServices = [
          "radarr"
          "sonarr"
          "lidarr"
          "readarr"
          "readarr-audio"
        ];
      };
      sabnzbd-metrics = {
        mode = "server";
        listen.port = config.services.prometheus.exporters.sabnzbd.port;
        target.port = config.services.prometheus.exporters.sabnzbd.port;
        target.namespace = "sabnzbd";
        allowMetrics = true;
      };
      consul-sabnzbd = {
        mode = "client";
        listen.socket = "/run/consul-checks/sabnzbd.sock";
        target.port = 8080;
        service = "sabnzbd";
      };
    };

    systemd.tmpfiles.settings."10-media-server" = {
      "/videos/downloads" = {
        d = {
          user = "sabnzbd";
          group = "media";
        };
        Z = {
          user = "sabnzbd";
          group = "media";
          mode = "~0775";
        };
      };
      "/videos/downloads/complete".d = {
        user = "sabnzbd";
        group = "media";
      };
      "/videos/downloads/incomplete".d = {
        user = "sabnzbd";
        group = "media";
      };
    };

    services.prometheus.exporters.sabnzbd = {
      enable = true;
      listenAddress = "::1";
      servers = [
        {
          baseUrl = "http://localhost:8080/sabnzbd";
          apiKeyFile = "/run/sabnzbd-creds.sock";
        }
      ];
    };
    systemd.services.prometheus-sabnzbd-exporter.networkNamespace = "sabnzbd";

    services.consul.services.sabnzbd = {
      port = 8080;

      metrics.enable = true;
      metrics.port = config.services.prometheus.exporters.sabnzbd.port;
      metrics.tls = true;

      checks.up = {
        http.path = "/";
        http.socket = "/run/consul-checks/sabnzbd.sock";
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    mjm.backups.media-server.paths = [
      "/var/lib/sabnzbd/admin"
      "/var/lib/sabnzbd/sabnzbd.ini"
    ];
  };
}
