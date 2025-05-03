{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    fileSystems."/videos" = {
      device = "media";
      fsType = "virtiofs";
    };

    users.groups.media.gid = 997;
  };
}
