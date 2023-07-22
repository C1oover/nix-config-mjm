{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "acme@matt.mattmoriarity.com";

  services.nginx = {
    enable = true;
    upstreams.ingress.servers = {
      # hardcoded for now, will need to be templated from consul
      "100.113.14.91" = {};
      "100.103.187.51" = {};
    };
    recommendedProxySettings = true;
    virtualHosts = {
      "auth.mattmoriarity.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://ingress";
          extraConfig = ''
            proxy_set_header Host $host;
            # proxy_set_header X-Real-IP $remote_addr;
            # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            # proxy_set_header X-Forwarded-Host $http_host;
            # proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
