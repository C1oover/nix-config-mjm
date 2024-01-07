{config, ...}: {
  services.prometheus.exporters.pve = {
    enable = true;
    configFile = config.age.secrets."pve.yml".path;
  };

  age.secrets."pve.yml".file = ../../../../secrets/pve-exporter-config.age;
}
