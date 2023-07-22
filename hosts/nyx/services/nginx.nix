let
  baseVhost = {
    http2 = false;
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://ingress";
      extraConfig = ''
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-Uri $request_uri;
      '';
    };
  };
in {
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "acme@matt.mattmoriarity.com";

  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      include /run/nginx-include/upstreams.conf;
    '';
    recommendedProxySettings = true;
    virtualHosts = {
      "auth.mattmoriarity.com" = baseVhost;
      "miniflux.mattmoriarity.com" = baseVhost;
      "linkding.mattmoriarity.com" = baseVhost;
      "git.mattmoriarity.com" = baseVhost;
      "paperless.mattmoriarity.com" = baseVhost;
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  services.consul-template.instances.nginx = {
    enable = true;
    settings = {
      # need to pick one of the raspberry pis tailscale address to use
      # unless i wanna bring the cloud into consul
      consul.address = "100.89.174.9:8500";
      template = [
        {
          source = ./upstreams.conf.tpl;
          destination = "/run/nginx-include/upstreams.conf";
          user = "nginx";
          group = "nginx";
          exec.command = ["systemctl" "reload" "nginx.service"];
        }
      ];
    };
  };

  systemd.services.nginx.wants = ["consul-template-nginx.service"];
}
