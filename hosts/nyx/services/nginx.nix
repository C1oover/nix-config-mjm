{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "acme@matt.mattmoriarity.com";

  services.nginx = {
    enable = true;
    upstreams.ingress.servers = {
      # hardcoded for now, will need to be templated from consul
      # "100.113.14.91:80" = {};
      "100.103.187.51:8080" = {};
    };
    recommendedProxySettings = true;
    virtualHosts = {
      "auth.mattmoriarity.com" = {
        http2 = false;
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://ingress";
          extraConfig = ''
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Forwarded-Ssl on;
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
