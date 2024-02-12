{
  vault.approles.roles.leto.tokenPolicies = [ "paperless" ];

  vault.policies.paperless.text = ''
    # Allow paperless jail to read the secret key
    path "kv/data/paperless" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.paper = {
    upstream.service.name = "paperless";

    extraLocationConfig = ''
      proxy_redirect off;
    '';
  };
}
