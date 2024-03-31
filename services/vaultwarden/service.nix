{
  ingress.virtualHosts.pass = {
    upstream.service.name = "vaultwarden";

    enableAuthProxy = false;
  };

  vault.services.vaultwarden = {
    commonPolicies = [ "backups" ];
    hosts = [ "leto" ];
  };
}
