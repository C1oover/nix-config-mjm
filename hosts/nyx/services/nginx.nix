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
        locations."/".proxyPass = "http://ingress";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
