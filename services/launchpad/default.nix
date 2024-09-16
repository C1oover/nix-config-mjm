{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.launchpad;
  pkg = import ../../apps/launchpad { inherit pkgs; };
in
{
  options.mjm.launchpad = {
    enable = mkEnableOption "launchpad web app";
  };

  config = mkIf cfg.enable {
    mjm.services.launchpad = {
      postgresql.enable = true;
      vault = {
        enable = true;
        loadedBy = [ "launchpad" ];
        keys = {
          gitlab_token = { };
          paperless_token = { };
        };
      };
    };
    mjm.otel-collector.enable = true;

    ingress.virtualHosts.launch = {
      upstream.service.name = "launchpad";
    };

    systemd.services.launchpad = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];
      environment = {
        OTEL_SERVICE_NAME = "launchpad";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317";
        OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";
        LAUNCHPAD_DATABASE_URL = "postgresql:///launchpad?host=/run/postgresql";
        LAUNCHPAD_BIND_ADDRESS = "[::]:4100";
        LAUNCHPAD_GITLAB_TOKEN_FILE = "%d/launchpad_gitlab_token";
        LAUNCHPAD_PAPERLESS_TOKEN_FILE = "%d/launchpad_paperless_token";
        LAUNCHPAD_ENABLE_PRETTY_OUTPUT = "false";
      };

      serviceConfig = {
        ExecStart = "${pkg}/bin/launchpad";
        Restart = "always";
        DynamicUser = true;
        User = "launchpad";
      };
    };

    networking.firewall.allowedTCPPorts = [ 4100 ];

    services.consul.services.launchpad = {
      port = 4100;
    };
  };
}
