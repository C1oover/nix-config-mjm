{
  services.prometheus.exporters.blackbox = {
    enable = true;
    configFile = ./blackbox.yml;
    listenAddress = "127.0.0.1";
  };
}
