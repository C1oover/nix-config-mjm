{
  terraform.resource.vault_mount.ssh_host_signer = {
    type = "ssh";
    path = "ssh-host-signer";

    max_lease_ttl_seconds = 315360000;
  };

  terraform.resource.vault_ssh_secret_backend_role.homelab_host = {
    name = "homelab-host";
    backend = "\${vault_mount.ssh_host_signer.path}";
    key_type = "ca";
    algorithm_signer = "default";
    allow_host_certificates = true;
    allow_bare_domains = true;
    allow_subdomains = true;
    allowed_domains = "home.mattmoriarity.com";
    ttl = 10 * 365 * 24 * 60 * 60;
  };

  vault.policies.common-host = {
    paths."ssh-host-signer/sign/homelab-host".capabilities = [ "update" ];
  };
}
