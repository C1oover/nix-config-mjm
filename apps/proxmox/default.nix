{
  imports = [ ./containers.nix ];

  terraform.terraform.required_providers.proxmox = {
    source = "registry.terraform.io/Telmate/proxmox";
    version = ">= 1.0.0";
  };
  terraform.provider.proxmox = {
    pm_api_url = "https://proxmox.midna.dev/api2/json";
    pm_tls_insecure = true;
    pm_api_token_id = "terraform-prov@pam!terraform-prov";
    pm_debug = true;
  };

  ingress.virtualHosts.proxmox = {
    upstream = {
      service.name = "proxmox";
      useSSL = true;
      ipHash = true;
    };

    enableAuthProxy = false;
  };
}
