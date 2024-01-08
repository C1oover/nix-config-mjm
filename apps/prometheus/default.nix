{
  ingress.virtualHosts = {
    alerts = {
      upstream.service.name = "alertmanager";
      external = true;
    };

    metrics = {
      upstream.service.name = "prometheus";
      external = true;
    };
  };
}
