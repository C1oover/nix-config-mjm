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
      deployment.tags = [ "svc-nut" ];

      power.ups = {
        enable = true;
        mode = if cfg.mode == "client" then "netclient" else "netserver";
      };

      vault.policies.common-nut = {
        paths."kv/data/prod/common/nut".capabilities = [ "read" ];
      };
      vault-secrets.wantedBy = [ "upsmon.service" ];
      vault-secrets.common.nut = {
        keys.secondary_password = { };
      };
    }

    (mkIf (cfg.mode == "client") {
      power.ups = {
        mode = "netclient";
        upsmon.monitor.${cfg.connectedUPSName} = {
          system = "${cfg.connectedUPSName}@${cfg.serverHostname}";
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

        upsmon.monitor = genAttrs upsNames (name: {
          system = "${name}@${cfg.serverHostname}";
          user = "upsmon";
          type = "primary";
          passwordFile = config.vault-secrets.services.nut.keys.primary_password.path;
        });

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

      vault.services.nut = { };
      vault-secrets.wantedBy = [ "upsd.service" ];
      vault-secrets.services.nut = {
        keys.primary_password = { };
      };
    })
  ]);
}
