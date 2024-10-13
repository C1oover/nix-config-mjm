{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.mjm.dns-server;
in
{
  options.mjm.dns-server.blocky = {
    upstreams = mkOption {
      type = types.listOf types.str;
      default = [
        "8.8.8.8"
        "8.8.4.4"
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;
      settings = {
        bootstrapDns = map (ip: { upstream = ip; }) cfg.blocky.upstreams;
        upstream.default = cfg.blocky.upstreams;
        blocking = {
          blackLists.ads = [
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            ''
              /\.tumblr-live\.com$/
            ''
          ];
          whiteLists.ads = [
            ''
              app.segment.com
              cdn.segment.com
              api.segment.io
              cdn.segment.io
            ''
          ];
          clientGroupsBlock.default = [ "ads" ];
          downloadAttempts = 120;
          downloadCooldown = "30s";
        };
        ports.dns = "127.0.0.1:1053";
        ports.http = 4000;
        prometheus = {
          enable = true;
          path = "/metrics";
        };
        caching.maxTime = "-1s"; # disable caching since it seems buggy
        customDNS = {
          mapping = {
            # make invidious work at home even without ipv6
            # stupid roku tv
            "yt.midna.dev" = "10.0.0.3,10.0.0.4,2601:282:167f:4e46:dea6:32ff:fe96:bc05,2601:282:167f:4e46:dea6:32ff:fed5:d840";
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 4000 ];

    services.consul.services.blocky = {
      port = 4000;
      metrics.enable = true;
      serviceConfig.tags = [ "http" ];

      checks.up = {
        http.path = "/";
        intervalSeconds = 30;
      };
    };
  };
}
