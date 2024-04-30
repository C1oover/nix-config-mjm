{
  vault.services.atticd.hosts = [ "leto" ];

  ingress.virtualHosts.attic = {
    upstream.service.name = "attic";
    enableAuthProxy = false;
    extraLocationConfig = ''
      proxy_buffering on;
    '';
  };
}
