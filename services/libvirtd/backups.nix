{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.mjm.libvirtd;
in
{
  options.mjm.libvirtd.vmsDataset = mkOption {
    type = types.str;
    default = "rpool/data";
  };

  config = mkIf cfg.enable {
    services.zrepl = {
      enable = true;
      settings = {
        global.monitoring = [
          {
            type = "prometheus";
            listen = ":9811";
          }
        ];
        jobs = [
          {
            name = "backup_to_local";
            type = "push";
            connect = {
              type = "local";
              listener_name = "local_sink";
              client_identity = "local";
            };
            filesystems = {
              "${cfg.vmsDataset}<" = true;
              "${cfg.vmsDataset}" = false;
            };
            snapshotting = {
              type = "periodic";
              prefix = "zrepl_";
              interval = "1h";
            };
            pruning = {
              keep_sender = [
                { type = "not_replicated"; }
                {
                  type = "last_n";
                  count = 3;
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  regex = "^zrepl_.*";
                  grid = "1x1d(keep=4) | 7x1d | 4x7d | 2x30d";
                }
              ];
            };
          }
          {
            name = "local_sink";
            type = "sink";
            serve = {
              type = "local";
              listener_name = "local_sink";
            };
            root_fs = "slow/backups";
            recv.placeholder.encryption = "inherit";
          }
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 9811 ];

    services.consul.services.zrepl = {
      port = 9811;
      metrics.enable = true;
    };
  };
}
