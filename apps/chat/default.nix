{
  ingress.virtualHosts.chat = {
    upstream.service.name = "conduit";
    enableAuthProxy = false;
  };
}
