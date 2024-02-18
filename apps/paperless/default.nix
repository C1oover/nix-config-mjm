{
  vault.policies.paperless = {
    paths."kv/data/paperless".capabilities = [ "read" ];
    approles = [ "leto" ];
  };

  ingress.virtualHosts.paper = {
    upstream.service.name = "paperless";

    extraLocationConfig = ''
      proxy_redirect off;
    '';
  };
}
