{ config, ... }:
{
  power.ups = {
    enable = true;
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
        passwordFile = config.age.secrets."nut-primary-password".path;
      };
      upsmon_secondary = {
        upsmon = "secondary";
        passwordFile = config.age.secrets."nut-secondary-password".path;
      };
    };
    upsd = {
      listen = [ { address = "0.0.0.0"; } ];
    };
    upsmon.monitor.tripplite = {
      system = "tripplite@10.0.0.2";
      user = "upsmon";
      type = "primary";
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

  age.secrets = {
    "nut-primary-password".file = ../../../secrets/nut-primary-password.age;
    "nut-secondary-password".file = ../../../secrets/nut-secondary-password.age;
  };
}
