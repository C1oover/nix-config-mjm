{
  ingress.virtualHosts = {
    alertmanager = {
      upstream.service.name = "alertmanager";
    };

    prometheus = {
      upstream.service.name = "prometheus";
    };
  };
}
