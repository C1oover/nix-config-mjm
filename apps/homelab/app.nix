{
  ingress.virtualHosts.homelab = {
    upstream.service.name = "homelab";
  };

  vault.policies.homelab.text = ''
    path "kv/data/paperless/client" {
      capabilities = ["read"]
    }

    path "kv/data/homelab" {
      capabilities = ["read"]
    }

    path "kv/data/taskwarrior" {
      capabilities = ["read"]
    }
  '';
}
