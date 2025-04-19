{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.services.peertube = {
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };
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

      secrets.secretsFile = "/run/credentials/peertube.service/peertube_secret_key";
      smtp.passwordFile = "/run/credentials/peertube.service/peertube_fastmail_password";

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

    mjm.authelia.oidcClients.peertube = {
      name = "PeerTube";
      clientId = "peertube";
      clientSecret = "$pbkdf2-sha512$310000$i/oOcdThnanFjq1JqrACMg$IUGcZqmZZtGOwjfYT1O1ZiMVk634D73XX9qgmwYDtJW3HVcNDRwU9JcX2pJp4WchFkx2iwArh8DWfbU.2xLYiw";
      redirectUris = [ "https://tube.midna.dev/plugins/auth-openid-connect/router/code-cb" ];
    };

    systemd.services.peertube = {
      serviceConfig.LoadCredential = [
        "peertube_fastmail_password:/run/peertube-creds.sock"
        "peertube_secret_key:/run/peertube-creds.sock"
      ];
    };

    systemd.tmpfiles.settings."10-media-server" = {
      "/videos/peertube".d = {
        user = "peertube";
        group = "media";
        mode = "~0775";
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
  };
}
