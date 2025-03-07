{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire.extraConfig.pipewire.raop-discover = {
      context.modules = [
        {
          name = "libpipewire-module-raop-discover";
          args = { };
        }
      ];
    };

    users.users.${config.mjm.username}.extraGroups = [ "pipewire" ];

    # airplay requires this
    networking.firewall.allowedUDPPorts = [
      6001
      6002
    ];
  };
}
