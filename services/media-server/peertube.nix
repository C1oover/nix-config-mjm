{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = "/var/lib/peertube";
        inherit (config.services.peertube) user group;
      }
    ];

    ingress.virtualHosts.tube = {
      upstream.service.name = "peertube";
      enableAuthProxy = false;
    };

    services.peertube = {
      enable = true;
      group = "media";

      localDomain = "tube.midna.dev";
      listenWeb = 443;
      configureNginx = true;
      enableWebHttps = true;

      database.createLocally = true;
      redis.createLocally = true;

      secrets.secretsFile = config.vault-secrets.services.media-server.keys.peertube_secrets.path;
      smtp.passwordFile = config.vault-secrets.services.media-server.keys.fastmail_password.path;

      dataDirs = [ "/videos/peertube" ];

      settings = {
        storage = {
          web_videos = "/videos/peertube/web-videos/";
          streaming_playlists = "/videos/peertube/streaming-playlists/";
          redundancy = "/videos/peertube/redundancy/";
        };
        smtp = {
          hostname = "smtp.fastmail.com";
          username = "matt@mattmoriarity.com";
          disable_starttls = true;
          from_address = "peertube@mj.midna.dev";
        };
      };
    };

    services.nginx.virtualHosts."tube.midna.dev" = {
      serverName = "_";
      listen = [
        {
          addr = "0.0.0.0";
          port = 9001;
        }
        {
          addr = "[::]";
          port = 9001;
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [
      # rtmp for live streaming
      1935
      # http
      9001
    ];

    services.consul.services.peertube = {
      port = 9001;
    };

    vault-secrets.services.media-server.keys = {
      fastmail_password.owner = "peertube";
      peertube_secrets.owner = "peertube";
    };
  };
}
