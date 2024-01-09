{
  pkgs,
  config,
  ...
}: {
  imports = [./blocky.nix];

  services.bind = {
    enable = true;
    cacheNetworks = [
      "127.0.0.0/24"
      "10.0.0.0/8"
    ];
    forwarders = ["127.0.0.1 port 1053"];

    extraOptions = ''
      dnssec-validation no;
    '';

    extraConfig = ''
      statistics-channels {
        inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
      };

      zone "consul" {
        type forward;
        forward only;
        forwarders {
          10.0.2.40 port 8600;
          10.0.2.42 port 8600;
          10.0.2.43 port 8600;
        };
      };
    '';

    zones."home.mattmoriarity.com" = {
      master = true;
      file = pkgs.writeText "home.mattmoriarity.com.zone" ''
        $TTL  1m
        @   IN  SOA localhost. matt.mattmoriarity.com. (
                          1
                         1m     ; Refresh
                         1h     ; Retry
                         1w     ; Expire
                         1h )   ; Negative Cache TTL
        @   IN  NS  localhost.

        $INCLUDE ${./home.mattmoriarity.com.hosts.zone}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    53
  ];

  networking.firewall.allowedUDPPorts = [
    53
  ];

  services.prometheus.exporters.bind = {
    enable = true;
    openFirewall = true;
  };

  services.consul.services.bind-exporter = let
    inherit (config.services.prometheus.exporters.bind) port;
  in {
    inherit port;
    meta.metrics_path = "/metrics";

    checks = [
      {
        http = "http://localhost:${toString port}/";
        interval = "30s";
        timeout = "5s";
      }
    ];
  };
}
