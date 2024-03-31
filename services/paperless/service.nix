{
  vault.services.paperless = {
    commonPolicies = [ "backups" ];
    hosts = [ "leto" ];
  };

  ingress.virtualHosts.paper = {
    upstream.service.name = "paperless";

    extraLocationConfig = ''
      proxy_redirect off;
    '';
  };
}
