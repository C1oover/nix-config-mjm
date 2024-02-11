{
  pkgs,
  outputs,
  config,
  ...
}:
let
  pkg = outputs.packages.${pkgs.system}.homelab;
  taskRc = pkgs.writeText "homelab-taskrc" ''
    data.location=$STATE_DIRECTORY/task
    taskd.ca=${../../../home/matt/features/taskwarrior/ca.crt}
    taskd.certificate=${../../../home/matt/features/taskwarrior/cert.crt}
    taskd.credentials=home/mjm/335503bd-9888-481a-b3e9-7d0c54e0b8bc
    taskd.key=$CREDENTIALS_DIRECTORY/taskd-key
    taskd.server=tasks.midna.dev:53589

    uda.reminder_id.type=string
    uda.reminder_id.label=Reminder
    uda.next_notification.type=date
    uda.next_notification.label=Notify
  '';
in
{
  systemd.services.homelab = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.service"
    ];
    path = with pkgs; [ taskwarrior ];
    environment = {
      OTEL_SERVICE_NAME = "homelab";
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";
      TASKRC = "${taskRc}";
      RELEASE_COOKIE = "default";
      HOME = "/var/lib/homelab";
    };

    preStart = ''
      mkdir -p $STATE_DIRECTORY/task
      task sync
    '';

    serviceConfig = {
      ExecStart = "${pkg}/bin/server";
      LoadCredential = [ "taskd-key:${config.age.secrets."taskwarrior.key".path}" ];
      EnvironmentFile = config.age.secrets."homelab.env".path;
      Restart = "always";
      DynamicUser = true;
      User = "homelab";
      StateDirectory = "homelab";
      WorkingDirectory = "/var/lib/homelab";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "homelab" ];
    ensureUsers = [
      {
        name = "homelab";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 4000 ];

  services.consul.services.homelab = {
    port = 4000;

    meta.metrics_path = "/metrics";

    checks = [
      {
        name = "homelab is ready";
        http = "http://localhost:4000/healthz";
        interval = "15s";
        timeout = "5s";
      }
    ];
  };

  age.secrets = {
    "taskwarrior.key".file = ../../../secrets/taskwarrior-key.age;
    "homelab.env".file = ../../../secrets/homelab-env.age;
  };
}
