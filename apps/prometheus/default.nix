{
  ingress.virtualHosts = {
    alerts = {
      upstream.service.name = "alertmanager";
    };

    metrics = {
      upstream.service.name = "prometheus";
    };
  };
}
