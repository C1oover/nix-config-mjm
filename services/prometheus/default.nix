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
      bindsTo = [ "netns-bridge@prometheus.service" ];
      after = [ "netns-bridge@prometheus.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/prometheus";
    };

    mjm.spire.tunnels = {
      prometheus = {
        mode = "server";
        namespace = "prometheus";
        port = 9090;
        target = "localhost:9090";
        allowIngress = true;
        allowedServices = [
          "alloy"
          "consul-agent"
          "grafana"
          "prometheus"
        ];
      };
      consul-prometheus = {
        mode = "client";
        socket = "/run/consul-checks/prometheus.sock";
        target = "localhost:9090";
        service = "prometheus";
      };
    };

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") === "prometheus.service" &&
            action.lookup("verb") === "reload-or-restart" &&
            subject.user === "prometheus") {
          return polkit.Result.YES;
        }

        return polkit.Result.NOT_HANDLED;
      });
    '';

    mjm.spire.agent.enable = true;
    systemd.services.prometheus-certs =
      let
        configFile = pkgs.writeText "prometheus-spiffe-helper.hcl" ''
          agent_address = "${config.mjm.spire.agent.socketPath}"
          cmd = "${pkgs.systemd}/bin/systemctl"
          cmd_args = "reload-or-restart prometheus"
          cert_dir = "/var/cache/prometheus"
          daemon_mode = true
          svid_file_name = "cert.pem"
          svid_key_file_name = "key.pem"
          svid_bundle_file_name = "bundle.pem"
        '';
      in
      {
        wantedBy = [
          "multi-user.target"
          "prometheus.service"
        ];
        before = [ "prometheus.service" ];
        after = [ "spire-agent.service" ];
        wants = [ "spire-agent.service" ];
        serviceConfig = {
          Type = "exec";
          ExecStart = "${pkgs.spiffe-helper}/bin/spiffe-helper -config ${configFile}";
          CacheDirectory = "prometheus";
          User = "prometheus";
          Group = "prometheus";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    systemd.services.prometheus.serviceConfig.CacheDirectory = "prometheus";

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
