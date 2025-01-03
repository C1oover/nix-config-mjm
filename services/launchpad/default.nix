{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.launchpad;
  pkg = pkgs.launchpad;

  serviceEnv = {
    OTEL_SERVICE_NAME = "launchpad";
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317";
    OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";
    LAUNCHPAD_DATABASE_URL = "postgresql:///launchpad?host=/run/postgresql";
    LAUNCHPAD_BIND_ADDRESS = "[::]:4100";
    LAUNCHPAD_GITLAB_TOKEN_FILE = "%d/launchpad_gitlab_token";
    LAUNCHPAD_NETBOX_TOKEN_FILE = "%d/launchpad_netbox_token";
    LAUNCHPAD_PAPERLESS_TOKEN_FILE = "%d/launchpad_paperless_token";
    LAUNCHPAD_REMINDERS_TOPIC_FILE = "%d/launchpad_reminders_topic";
    LAUNCHPAD_ENABLE_PRETTY_OUTPUT = "false";
  };
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
        loadedBy = [
          "launchpad"
          "launchpad-reminders"
        ];
        keys = {
          gitlab_token = { };
          netbox_token = { };
          paperless_token = { };
          reminders_topic = { };
        };
      };
    };
    mjm.otel-collector.enable = true;

    ingress.virtualHosts.launch = {
      upstream.service.name = "launchpad";
      useIPv4Proxy = true;
    };

    systemd.services.launchpad = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];
      environment = serviceEnv;

      serviceConfig = {
        ExecStart = "${pkg}/bin/launchpad serve";
        Restart = "always";
        DynamicUser = true;
        User = "launchpad";
      };
    };

    systemd.services.launchpad-reminders = {
      restartIfChanged = false;
      environment = serviceEnv;

      after = [ "postgresql.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkg}/bin/launchpad process-reminders";
        DynamicUser = true;
        User = "launchpad";
      };
    };

    systemd.timers.launchpad-reminders = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5:10";
      };
    };

    networking.firewall.allowedTCPPorts = [ 4100 ];

    services.consul.services.launchpad = {
      port = 4100;

      checks.up = {
        http.path = "/healthz";
        intervalSeconds = 30;
      };
    };
  };
}
