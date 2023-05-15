{
  services.bind = {
    enable = true;
    cacheNetworks = [
      "10.0.0.0/8"
    ];

    extraOptions = ''
      include "/run/named/forwarders.conf";
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
