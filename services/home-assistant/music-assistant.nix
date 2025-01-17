{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.home-assistant;
in
{
  config = mkIf cfg.enable {
    mjm.state.directories = [ "/var/lib/private/music-assistant" ];

    ingress.virtualHosts.tunes = {
      upstream.service.name = "music-assistant";
    };

    services.music-assistant = {
      enable = true;
      providers = [
        # "airplay"
        # "builtin"
        "dlna"
        "hass"
        # "hass_players"
        "opensubsonic"
        "slimproto"
        # "snapcast"
      ];
    };

    # systemd.services.music-assistant.path = [ pkgs.snapcast ];

    networking.firewall.allowedTCPPorts = [
      1704
      1705
      1780
      8095
      8097
      8098
    ];

    networking.firewall.allowedTCPPortRanges = [
      {
        from = 4953;
        to = 5153;
      }
    ];

    # airplay (via cliraop) will open UDP ports from the local IP port range,
    # and will expect the device playing the music to be able to connect to it.
    # so we have to open the whole stupid range.
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];

    services.consul.services.music-assistant = {
      port = 8095;

      checks.up = {
        http.path = "/";
      };
    };
  };
}
