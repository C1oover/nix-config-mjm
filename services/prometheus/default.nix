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
      upstream.service.name = "prometheus";
    };

    services.prometheus = {
      enable = true;
      checkConfig = "syntax-only";
      webExternalUrl = "https://metrics.midna.dev";

      globalConfig = {
        scrape_interval = "60s";
        evaluation_interval = "30s";
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];

    services.consul.services.prometheus = {
      inherit (config.services.prometheus) port;
      metrics.enable = true;

      checks.up = {
        http.path = "/-/ready";
        intervalSeconds = 30;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests.prometheus) config-reload;
      inherit (pkgs.nixosTests.prometheus-exporters) blackbox;
    };
  };
}
