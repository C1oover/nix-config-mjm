{
  vault.services.paperless.hosts = [ "leto" ];

  ingress.virtualHosts.paper = {
    upstream.service.name = "paperless";

    extraLocationConfig = ''
      proxy_redirect off;
    '';
  };
}
