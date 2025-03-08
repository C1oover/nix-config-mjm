{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.libvirtd;
in
{
  config = mkIf cfg.enable {
    services.zrepl = {
      enable = true;
      settings = {
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
              "rpool/data<" = true;
              "rpool/data" = false;
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
  };
}
