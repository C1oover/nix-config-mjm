{ config, lib, ... }:
let
  inherit (lib)
    genAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.mjm.nut;

  upsNames = [
    "or500"
    "smart500"
  ];
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

    connectedUPSName = mkOption {
      type = types.enum upsNames;
    };

    serverHostname = mkOption {
      type = types.str;
      default = "10.0.0.2";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      mjm.services.nut-client = {
        vault = {
          enable = true;
          useSpiffeIdentity = true;
        };
      };

      power.ups = {
        enable = true;
        mode = if cfg.mode == "client" then "netclient" else "netserver";
      };
    }

    (mkIf (cfg.mode == "client") {
      power.ups = {
        mode = "netclient";
        upsmon.monitor.${cfg.connectedUPSName} = {
          system = "${cfg.connectedUPSName}@${cfg.serverHostname}";
          user = "upsmon_secondary";
          type = "secondary";
          passwordFile = "/run/nut-client-creds.sock";
        };
      };

      mjm.spire.creds.nut-client = {
        aliases = {
          "upsmon.service/upsmon_password_${cfg.connectedUPSName}" = "nut-client/secondary_password";
        };
      };
    })

    (mkIf (cfg.mode == "server") {
      mjm.services.nut = {
        vault = {
          enable = true;
          useSpiffeIdentity = true;
        };
      };

      power.ups = {
        mode = "netserver";
        openFirewall = true;

        ups.or500 = {
          driver = "usbhid-ups";
          port = "auto";
          directives = [
            ''vendorid = "0764"''
            ''productid = "0601"''
          ];
        };
        ups.smart500 = {
          driver = "tripplite_usb";
          port = "auto";
          directives = [
            ''vendorid = "09ae"''
            ''productid = "0001"''
          ];
        };

        users = {
          upsmon = {
            upsmon = "primary";
            passwordFile = "/run/nut-creds.sock";
          };
          upsmon_secondary = {
            upsmon = "secondary";
            passwordFile = "/run/nut-client-creds.sock";
          };
        };

        upsd = {
          listen = [ { address = "0.0.0.0"; } ];
        };

        upsmon.monitor = genAttrs upsNames (name: {
          system = "${name}@${cfg.serverHostname}";
          user = "upsmon";
          type = "primary";
          passwordFile = "/run/nut-creds.sock";
        });
      };

      mjm.spire.creds = {
        nut.aliases = {
          "upsmon.service/upsmon_password_or500" = "nut/primary_password";
          "upsmon.service/upsmon_password_smart500" = "nut/primary_password";
          "upsd.service/upsdusers_password_upsmon" = "nut/primary_password";
        };
        nut-client.aliases = {
          "upsd.service/upsdusers_password_upsmon_secondary" = "nut-client/secondary_password";
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

      services.consul.services.nut-exporter = {
        inherit (config.services.prometheus.exporters.nut) port;

        checks.up = {
          http.path = "/";
        };
      };
    })
  ]);
}
