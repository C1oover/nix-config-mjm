{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  cfg = config.cloover.desktop;
in
{
  config = mkIf cfg.enable {
    services.resolved.enable = true;

    networking.networkmanager = {
      enable = mkDefault true;
      wifi.backend = "iwd";
    };
    systemd.services.NetworkManager-wait-online.enable = false;

    cloover.state.directories = mkIf config.networking.networkmanager.enable [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
    ];
  };
}
