{
  imports = [
    ./containers.nix
  ];

  terraform.required_providers.proxmox = {
    source = "Telmate/proxmox";
    version = ">= 1.0.0";
  };
  provider.proxmox = {
    pm_api_url = "https://proxmox.home.mattmoriarity.com/api2/json";
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

    extraLocationConfig = ''
      proxy_ssl_trusted_certificate /etc/nginx/ssl/proxmox.ca.crt;
    '';
  };

  ingress.extraTemplates."secrets/proxmox.ca.crt".source = ./proxmox.ca.crt;
}
