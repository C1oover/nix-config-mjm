{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.mjm.nut;
in
{
  options.mjm.nut = {
    enable = mkEnableOption "NUT";

    mode = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      default = "client";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      deployment.tags = [ "svc-nut" ];

      power.ups = {
        enable = true;
        mode = if cfg.mode == "client" then "netclient" else "netserver";
        upsmon.monitor.tripplite.system = "tripplite@10.0.0.2";
      };

      vault-secrets.wantedBy = [ "upsmon.service" ];
      vault-secrets.common.nut = {
        keys.secondary_password = { };
      };
    }

    (mkIf (cfg.mode == "client") {
      power.ups = {
        mode = "netclient";
        upsmon.monitor.tripplite = {
          user = "upsmon_secondary";
          type = "secondary";
          passwordFile = config.vault-secrets.common.nut.keys.secondary_password.path;
        };
      };
    })

    (mkIf (cfg.mode == "server") {
      deployment.tags = [ "svc-nut-server" ];

      power.ups = {
        mode = "netserver";
        openFirewall = true;

        ups.tripplite = {
          driver = "usbhid-ups";
          port = "auto";
          directives = [
            ''vendorid = "09ae"''
            ''productid = "3024"''
          ];
        };

        users = {
          upsmon = {
            upsmon = "primary";
            passwordFile = config.vault-secrets.services.nut.keys.primary_password.path;
          };
          upsmon_secondary = {
            upsmon = "secondary";
            passwordFile = config.vault-secrets.common.nut.keys.secondary_password.path;
          };
        };

        upsd = {
          listen = [ { address = "0.0.0.0"; } ];
        };

        upsmon.monitor.tripplite = {
          user = "upsmon";
          type = "primary";
          passwordFile = config.vault-secrets.services.nut.keys.primary_password.path;
        };
      };

      services.prometheus.exporters.nut = {
        enable = true;
        openFirewall = true;
        nutVariables = [
          "battery.charge"
          "battery.runtime"
          "battery.voltage"
          "battery.voltage.nominal"
          "input.voltage"
          "input.voltage.nominal"
          "ups.load"
          "ups.status"
        ];
        extraFlags = [ "--log.level=debug" ];
      };

      services.consul.services.nut-exporter =
        let
          inherit (config.services.prometheus.exporters.nut) port;
        in
        {
          inherit port;
          meta.metrics_path = "/ups_metrics";

          checks = [
            {
              name = "nut-exporter is ready";
              http = "http://localhost:${toString port}/";
              interval = "15s";
              timeout = "10s";
            }
          ];
        };

      vault-secrets.wantedBy = [ "upsd.service" ];
      vault-secrets.services.nut = {
        keys.primary_password = { };
      };
    })
  ]);
}
