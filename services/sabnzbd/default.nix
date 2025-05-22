{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.sabnzbd;
in
{
  options.mjm.sabnzbd = {
    enable = mkEnableOption "sabnzbd";
  };

  config = mkIf cfg.enable {
    mjm.services.sabnzbd = {
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/sabnzbd";
        inherit (config.services.sabnzbd) user group;
      }
    ];
    microvm.shares = [
      {
        proto = "virtiofs";
        tag = "media";
        source = "/mnt/slow/media";
        mountPoint = "/videos";
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
    users.groups.media.gid = 997;
    users.users.sabnzbd.extraGroups = [ "media" ];

    mjm.spire.tunnels = {
      sabnzbd = {
        id = "sabnzbd";
        mode = "server";
        listen.port = 28080;
        target.port = 8080;
        allowIngress = true;
        allowedServices = [
          "radarr"
          "sonarr"
          "lidarr"
          "readarr"
          "readarr-audio"
        ];
      };
      sabnzbd-metrics = {
        id = "sabnzbd";
        mode = "server";
        listen.port = 19387;
        target.port = config.services.prometheus.exporters.sabnzbd.port;
        allowMetrics = true;
      };
    };

    systemd.tmpfiles.settings."10-sabnzbd" = {
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

    services.consul.services.sabnzbd = {
      port = 28080;

      metrics.enable = true;
      metrics.port = 19387;
      metrics.tls = true;

      checks.up = {
        http.path = "/";
        http.port = 8080;
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    mjm.backups.sabnzbd = {
      paths = [
        "/var/lib/sabnzbd/admin"
        "/var/lib/sabnzbd/sabnzbd.ini"
      ];
    };
  };
}
