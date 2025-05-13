{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;

  secrets = config.systemd.services.peertube.credentials.peertube;
in
{
  config = mkIf cfg.enable {
    mjm.services.peertube = {
      vault.enable = true;
    };
    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = "/var/lib/peertube";
        inherit (config.services.peertube) user group;
      }
    ];

    ingress.virtualHosts.tube = {
      upstream = {
        service.name = "peertube";
        tls.enable = true;
      };

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

      secrets.secretsFile = secrets.secret_key.path;
      smtp.passwordFile = secrets.fastmail_password.path;

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
      credentials.peertube = {
        fastmail_password = { };
        secret_key = { };
      };
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
        { addr = "unix:/run/nginx/peertube.sock"; }
      ];
    };

    systemd.tmpfiles.settings."10-peertube" = {
      "/run/nginx".d = {
        user = "nginx";
        mode = "0755";
      };
    };

    mjm.spire.tunnels = {
      peertube = {
        mode = "server";
        listen.port = 9001;
        target.socket = "/run/nginx/peertube.sock";
        allowIngress = true;
      };
    };

    networking.firewall.allowedTCPPorts = [
      # rtmp for live streaming
      1935
    ];

    services.consul.services.peertube = {
      port = 9001;
    };
  };
}
