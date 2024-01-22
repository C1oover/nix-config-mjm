{
  ingress.virtualHosts.pass = {
    upstream.service.name = "vaultwarden";

    enableAuthProxy = false;
  };
}
