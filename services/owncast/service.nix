{
  ingress.virtualHosts.stream = {
    upstream.service.name = "owncast";
    enableAuthProxy = false;
  };
}
