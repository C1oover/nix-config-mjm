{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.prometheus;
in
{
  options.mjm.prometheus = {
    enable = mkEnableOption "prometheus";

    dnsServers = mkOption {
      type = types.listOf types.str;
      default = [ "10.0.0.5" ];
    };
  };

  imports = [
    ./alertmanager.nix
    ./blackbox.nix
    ./consul-exporter.nix
    ./jobs
  ];

  config = mkIf cfg.enable {
    mjm.services.prometheus = { };
    mjm.state.services = [ "prometheus" ];

    ingress.virtualHosts.metrics = {
      upstream = {
        service.name = "prometheus";
        tls.enable = true;
      };
    };

    services.prometheus = {
      enable = true;
      listenAddress = "[::1]";
      port = 9090;
      checkConfig = "syntax-only";
      webExternalUrl = "https://metrics.midna.dev";
      extraFlags = [ "--web.enable-remote-write-receiver" ];

      globalConfig = {
        scrape_interval = "60s";
        evaluation_interval = "30s";
      };
    };

    systemd.services.prometheus = {
      bindsTo = [
        "netns-bridge@prometheus.service"
        "spiffe-certs@prometheus.service"
      ];
      after = [
        "netns-bridge@prometheus.service"
        "spiffe-certs@prometheus.service"
      ];
      serviceConfig.NetworkNamespacePath = "/run/netns/prometheus";
    };

    mjm.spire.tunnels = {
      prometheus = {
        mode = "server";
        listen.port = 9090;
        target.port = 9090;
        target.namespace = "prometheus";
        allowIngress = true;
        allowConsul = true;
        allowedServices = [
          "alloy"
          "grafana"
          "prometheus"
        ];
      };
      consul-prometheus = {
        mode = "client";
        listen.socket = "/run/consul-checks/prometheus.sock";
        target.port = 9090;
        service = "prometheus";
      };
    };

    mjm.spire.agent.enable = true;
    mjm.spire.certs.prometheus = {
      systemd.unit = "prometheus.service";
      systemd.action = "reload-or-restart";
      user = "prometheus";
    };

    services.consul.services.prometheus = {
      port = 9090;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/-/ready";
        http.socket = "/run/consul-checks/prometheus.sock";
        intervalSeconds = 30;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests.prometheus) config-reload;
      inherit (pkgs.nixosTests.prometheus-exporters) blackbox;
    };
  };
}
