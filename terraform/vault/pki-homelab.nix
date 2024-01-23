{
  resource.vault_mount.pki_homelab = {
    path = "pki-homelab";
    type = "pki";

    max_lease_ttl_seconds = 315360000;
  };

  resource.vault_pki_secret_backend_config_urls.homelab_config_urls = {
    backend = "\${vault_mount.pki_homelab.path}";

    crl_distribution_points = [
      "http://vault.service.consul:8200/v1/\${vault_mount.pki_homelab.path}/crl"
    ];
    issuing_certificates = [
      "http://vault.service.consul:8200/v1/\${vault_mount.pki_homelab.path}/ca"
    ];
  };

  resource.vault_pki_secret_backend_role.homelab = {
    backend = "\${vault_mount.pki_homelab.path}";
    name = "homelab";

    max_ttl = 604800;
    generate_lease = true;

    key_usage = [
      "DigitalSignature"
      "KeyAgreement"
      "KeyEncipherment"
    ];

    allow_localhost = false;
    allow_bare_domains = false;
    allow_subdomains = true;
    allow_glob_domains = false;
    allowed_domains = [
      "homelab"
      "home.mattmoriarity.com"
    ];
  };

  data.vault_generic_secret.homelab_ca = {
    path = "pki-homelab/cert/ca";
  };
}
