{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.prometheus;
in
{
  config = mkIf cfg.enable {
    services.prometheus.exporters.blackbox = {
      enable = true;
      configFile = ./blackbox.yml;
      listenAddress = "127.0.0.1";
    };

    systemd.services.prometheus-blackbox-exporter = {
      bindsTo = [ "netns-bridge@prometheus.service" ];
      after = [ "netns-bridge@prometheus.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/prometheus";
    };
  };
}
