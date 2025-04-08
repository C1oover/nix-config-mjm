{
  pkgs,
  config,
  lib,
  utils,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.launchpad;
  pkg = pkgs.launchpad;

  serviceEnv = {
    OTEL_SERVICE_NAME = "launchpad";
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";
    OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";
    LAUNCHPAD_DATABASE_URL = "postgresql:///launchpad?host=/run/postgresql";
    LAUNCHPAD_GITLAB_TOKEN_FILE = "%d/launchpad_gitlab_token";
    LAUNCHPAD_PAPERLESS_TOKEN_FILE = "%d/launchpad_paperless_token";
    LAUNCHPAD_REMINDERS_TOPIC_FILE = "%d/launchpad_reminders_topic";
    LAUNCHPAD_ENABLE_PRETTY_OUTPUT = "false";
  };

  keys = [
    "gitlab_token"
    "paperless_token"
    "reminders_topic"
  ];
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
        # loadedBy = [
        #   "launchpad"
        #   "launchpad-reminders"
        # ];
        # keys = {
        #   gitlab_token = { };
        #   paperless_token = { };
        #   reminders_topic = { };
        # };
      };
    };
    mjm.otel-collector.enable = true;

    ingress.virtualHosts.launch = {
      upstream = {
        service.name = "launchpad";
        tls.enable = true;
      };

      useIPv4Proxy = true;
    };

    systemd.sockets.launchpad-creds = {
      wantedBy = [ "sockets.target" ];
      partOf = [ "launchpad-creds.service" ];
      socketConfig = {
        ListenStream = "/run/launchpad-creds.sock";
        SocketMode = "0600";
      };
    };

    systemd.services.launchpad-creds = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "launchpad-creds.socket"
      ];
      requires = [
        "launchpad-creds.socket"
      ];

      environment = {
        SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
        VAULT_ADDR = "https://vault.service.consul:8250";
      };

      serviceConfig = {
        Type = "notify";
        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe pkgs.spire-secrets)
          "-path"
          "prod/services/launchpad"
          "server"
        ];
        DynamicUser = true;
      };
    };

    systemd.sockets.launchpad = {
      wantedBy = [ "sockets.target" ];
      partOf = [ "launchpad.service" ];
      socketConfig = {
        ListenStream = "/run/launchpad.sock";
      };
    };

    systemd.services.launchpad = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "launchpad.socket"
      ];
      requires = [ "launchpad.socket" ];
      environment = serviceEnv;

      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkg}/bin/launchpad serve";
        Restart = "always";
        DynamicUser = true;
        User = "launchpad";
        LoadCredential = map (k: "launchpad_${k}:/run/launchpad-creds.sock") keys;
      };
    };

    systemd.services.launchpad-reminders = {
      restartIfChanged = false;
      environment = serviceEnv;

      after = [
        "network.target"
        "postgresql.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkg}/bin/launchpad process-reminders";
        DynamicUser = true;
        User = "launchpad";
        LoadCredential = map (k: "launchpad_${k}:/run/launchpad-creds.sock") keys;
      };
    };

    systemd.timers.launchpad-reminders = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5:10";
      };
    };

    mjm.spire.tunnels.launchpad = {
      mode = "server";
      port = 4100;
      target = "unix:/run/launchpad.sock";
      allowIngress = true;
    };

    services.consul.services.launchpad = {
      port = 4100;

      checks.up = {
        # consul can't do normal http checks to unix sockets, and the
        # tunnel only allows requests from the ingress, so here we are.
        script.args = [
          (lib.getExe pkgs.curl)
          "--no-progress-meter"
          "--fail-with-body"
          "--unix-socket"
          "/run/launchpad.sock"
          "http://localhost/healthz"
        ];
        intervalSeconds = 30;
      };
    };
  };
}
