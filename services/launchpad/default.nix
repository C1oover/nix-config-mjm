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
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318";
    OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";
    LAUNCHPAD_DATABASE_URL = "postgresql:///launchpad?host=/run/postgresql";
    LAUNCHPAD_GITLAB_TOKEN_FILE = "%d/launchpad_gitlab_token";
    LAUNCHPAD_PAPERLESS_TOKEN_FILE = "%d/launchpad_paperless_token";
    LAUNCHPAD_REMINDERS_TOPIC_FILE = "%d/launchpad_reminders_topic";
    LAUNCHPAD_ENABLE_PRETTY_OUTPUT = "false";
  };

  creds = {
    gitlab_token = { };
    paperless_token = { };
    reminders_topic = { };
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
      };
    };

    ingress.virtualHosts.launch = {
      upstream = {
        service.name = "launchpad";
        tls.enable = true;
      };

      useIPv4Proxy = true;
    };

    mjm.networkd.macvlan.enable = true;

    systemd.sockets.launchpad = {
      description = "Launchpad Web Portal Socket";
      wantedBy = [ "sockets.target" ];
      partOf = [ "launchpad.service" ];
      socketConfig.ListenStream = "/run/launchpad.sock";
    };

    systemd.services.launchpad = {
      description = "Launchpad Web Portal";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "launchpad.socket"
      ];
      requires = [ "launchpad.socket" ];
      bindsTo = [ "netns-bridge@launchpad.service" ];
      environment = serviceEnv;
      credentials.launchpad = creds;

      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkg}/bin/launchpad serve";
        Restart = "always";
        DynamicUser = true;
        User = "launchpad";
        PrivateTmp = true;
        NetworkNamespacePath = "/run/netns/launchpad";
      };
    };

    systemd.services.launchpad-reminders = {
      description = "Send Launchpad Reminders";
      restartIfChanged = false;
      environment = serviceEnv;
      credentials.launchpad = creds;

      after = [
        "network.target"
        "postgresql.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkg}/bin/launchpad process-reminders";
        DynamicUser = true;
        User = "launchpad";
      };
    };

    systemd.timers.launchpad-reminders = {
      description = "Send Launchpad Reminders";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5:10";
      };
    };

    mjm.spire.tunnels = {
      launchpad = {
        mode = "server";
        listen.port = 4100;
        target.socket = "/run/launchpad.sock";
        allowIngress = true;
      };
      launchpad-alloy = {
        mode = "client";
        listen.port = 4318;
        listen.namespace = "launchpad";
        target.socket = "/run/alloy-otlphttp.sock";
        service = "alloy";
      };
      launchpad-alertmanager = {
        mode = "client";
        listen.port = 9093;
        listen.namespace = "launchpad";
        target.service = "alertmanager";
        target.port = 9093;
      };
      launchpad-paperless = {
        mode = "client";
        listen.port = 28981;
        listen.namespace = "launchpad";
        target.service = "paperless";
        target.port = 28981;
      };
    };

    services.consul.services.launchpad = {
      port = 4100;

      checks.up = {
        http.path = "/healthz";
        http.socket = "/run/launchpad.sock";
        intervalSeconds = 30;
      };
    };
  };
}
