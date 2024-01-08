{
  ingress.virtualHosts.consul = {
    upstream.service = {
      name = "consul";
      port = 8500;
    };
    external = true;
  };
}
