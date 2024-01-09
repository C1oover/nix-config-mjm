{
  ingress.virtualHosts.budget = {
    upstream.service.name = "actual";
    external = true;
  };
}
