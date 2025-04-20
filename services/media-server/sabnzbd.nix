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
        useSpiffeIdentity = true;
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
      upstream.service.name = "sabnzbd";
    };

    services.sabnzbd = {
      enable = true;
    };

    users.users.sabnzbd.extraGroups = [ "media" ];

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
      openFirewall = true;
      listenAddress = "::";
      servers = [
        {
          baseUrl = "http://localhost:8080/sabnzbd";
          apiKeyFile = "/run/sabnzbd-creds.sock";
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];

    services.consul.services.sabnzbd = {
      port = 8080;

      metrics.enable = true;
      metrics.port = config.services.prometheus.exporters.sabnzbd.port;

      checks.up = {
        http.path = "/";
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    mjm.backups.mediaserver.paths = [
      "/var/lib/sabnzbd/admin"
      "/var/lib/sabnzbd/sabnzbd.ini"
    ];
  };
}
