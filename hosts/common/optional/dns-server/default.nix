{
  services.bind = {
    enable = true;
    cacheNetworks = [
      "10.0.0.0/8"
    ];

    extraOptions = ''
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
      file = ./home.mattmoriarity.com.zone;
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
        {
          source = ./home.mattmoriarity.com.ingress.zone;
          destination = "/run/named/home.mattmoriarity.com.zone";
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
