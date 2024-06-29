{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.homelab;

  pkg = (import ../../packages { inherit pkgs; }).homelab;
  taskRc = pkgs.writeText "homelab-taskrc" ''
    data.location=$STATE_DIRECTORY/task
    taskd.ca=${../../home/matt/features/taskwarrior/ca.crt}
    taskd.certificate=${../../home/matt/features/taskwarrior/cert.crt}
    taskd.credentials=home/mjm/335503bd-9888-481a-b3e9-7d0c54e0b8bc
    taskd.key=$CREDENTIALS_DIRECTORY/homelab_taskwarrior_key
    taskd.server=tasks.midna.dev:53589

    uda.reminder_id.type=string
    uda.reminder_id.label=Reminder
    uda.next_notification.type=date
    uda.next_notification.label=Notify
  '';
in
{
  options.mjm.homelab = {
    enable = mkEnableOption "homelab web app";
  };

  config = mkIf cfg.enable {
    mjm.services.homelab = {
      postgresql.enable = true;
    };
    mjm.otel-collector.enable = true;

    ingress.virtualHosts.homelab = {
      upstream.service.name = "homelab";
    };

    systemd.services.homelab = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];
      path = with pkgs; [
        restic
        taskwarrior
      ];
      environment = {
        OTEL_SERVICE_NAME = "homelab";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";
        OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=prod";
        TASKRC = "${taskRc}";
        RELEASE_COOKIE = "default";
        HOME = "/var/lib/homelab";
        RESTIC_PASSWORD_FILE = "%d/homelab_restic_password";
      };

      preStart = ''
        mkdir -p $STATE_DIRECTORY/task
        task sync
      '';

      serviceConfig = {
        ExecStart = "${pkg}/bin/server";
        Restart = "always";
        DynamicUser = true;
        User = "homelab";
        StateDirectory = "homelab";
        WorkingDirectory = "/var/lib/homelab";
        # TODO harden
      };
    };

    vault.services.homelab.commonPolicies = [ "backups" ];
    vault-secrets.services.homelab = {
      loadedBy = [ "homelab" ];
      keys = {
        gitlab_token = { };
        netbox_token = { };
        paperless_token = { };
        restic_password = { };
        secret_key_base = { };
        taskwarrior_key = { };
      };
    };
    vault-secrets.common.backups = {
      loadedBy = [ "homelab" ];
      keys = {
        garage_key_id = { };
        garage_secret_key = { };
        b2_key_id = { };
        b2_application_key = { };
      };
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
  };
}
