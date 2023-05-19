{pkgs, ...}: {
  services.bind = {
    enable = true;
    cacheNetworks = [
      "127.0.0.0/24"
      "10.0.0.0/8"
    ];

    extraOptions = ''
      dnssec-validation no;
      include "/run/named/forwarders.conf";
    '';

    extraConfig = ''
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
        $INCLUDE ${./home.mattmoriarity.com.ingress.zone}
      '';
    };
  };

  # bind can't start without the files rendered by consul-template
  systemd.services.bind = {
    requires = ["consul-template-bind.service"];
    after = ["consul-template-bind.service"];
    startLimitIntervalSec = 60;
    startLimitBurst = 10;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  services.consul-template.instances.bind = {
    settings = {
      template = [
        {
          source = ./forwarders.conf;
          destination = "/run/named/forwarders.conf";
          command = "systemctl reload bind";
          error_on_missing_key = true;
          user = "named";
          group = "named";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    53
  ];

  networking.firewall.allowedUDPPorts = [
    53
  ];
}
