{
  vault.databases.roles.paperless = {
    ttl = "short";
  };
  vault.approles.roles.paperless = {};
  vault.approles.roles.leto.tokenPolicies = ["paperless"];

  vault.policies.paperless.text = ''
    # Allow paperless jail to read credentials for accessing paperless database
    path "database/creds/paperless" {
      capabilities = ["read"]
    }

    # Allow paperless jail to read the secret key
    path "kv/data/paperless" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.paper = {
    upstream.service.name = "paperless";

    external = true;

    extraLocationConfig = ''
      proxy_redirect off;
    '';
  };
}
