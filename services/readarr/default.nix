{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.readarr;

  dataDir = "/var/lib/readarr";
in
{
  options.mjm.readarr = {
    enable = mkEnableOption "Readarr";

    suffix = mkOption {
      type = types.str;
      default = "";
    };

    mediaDir = mkOption {
      type = types.path;
    };

    subdomain = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    mjm.services."readarr${cfg.suffix}" = {
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = dataDir;
        inherit (config.services.readarr) user group;
      }
    ];
    microvm.shares = [
      {
        proto = "virtiofs";
        tag = "media";
        source = "/mnt/slow/media";
        mountPoint = "/videos";
      }
    ];

    services.readarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };

    users.groups.media.gid = 997;
    users.users.readarr.extraGroups = [ "media" ];

    systemd.tmpfiles.settings."10-readarr" = {
      ${cfg.mediaDir} = {
        d = {
          user = "readarr";
          group = "media";
        };
        Z = {
          user = "readarr";
          group = "media";
          mode = "~0775";
        };
      };
    };

    services.prometheus.exporters.exportarr-readarr = {
      enable = true;
      listenAddress = "::1";
      apiKeyFile = "/run/readarr${cfg.suffix}-creds.sock";
      url = "http://127.0.0.1:8787";
    };

    mjm.spire.creds = {
      "readarr${cfg.suffix}".aliases = {
        "prometheus-exportarr-readarr-exporter.service/api-key" = "readarr${cfg.suffix}/api_key";
      };
    };

    mjm.spire.tunnels = {
      readarr = {
        id = "readarr${cfg.suffix}";
        mode = "server";
        listen.port = 18787;
        target.port = 8787;
        allowIngress = true;
      };
      readarr-metrics = {
        id = "readarr${cfg.suffix}";
        mode = "server";
        listen.port = 19706;
        target.port = 9708;
        allowMetrics = true;
      };
      readarr-sabnzbd = {
        id = "readarr${cfg.suffix}";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        target.service = "sabnzbd";
        target.port = 28080;
      };
    };

    services.consul.services."readarr${cfg.suffix}" = {
      port = 18787;

      metrics.enable = true;
      metrics.port = 19706;
      metrics.tls = true;

      checks.up = {
        http.path = "/";
        http.port = 8787;
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    ingress.virtualHosts.${cfg.subdomain} = {
      upstream = {
        service.name = "readarr${cfg.suffix}";
        tls.enable = true;
      };
    };

    mjm.backups."readarr${cfg.suffix}" = {
      paths = [ dataDir ];
      exclude = [ "${dataDir}/logs" ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 ${dataDir}/readarr.db ".backup '${dataDir}/readarr-backup.db'"
      '';
      backupCleanupCommand = ''
        rm ${dataDir}/readarr-backup.db
      '';
    };
  };
}
