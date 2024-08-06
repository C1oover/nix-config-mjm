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
      package = pkgs.music-assistant.overrideAttrs (oldAttrs: {
        preBuild =
          let
            rpath = lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ];
          in
          ''
            patchelf \
              --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
              --set-rpath "${rpath}" \
              music_assistant/server/providers/airplay/bin/cliraop-linux-x86_64
          '';
      });
      providers = [
        # "airplay"
        # "builtin"
        "dlna"
        # "hass"
        # "hass_players"
        "opensubsonic"
        "slimproto"
        "snapcast"
      ];
    };

    systemd.services.music-assistant.path = [ pkgs.snapcast ];

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

    services.consul.services.music-assistant = {
      port = 8095;

      checks = [
        {
          name = "music-assistant is ready";
          http = "http://localhost:8095/";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };
  };
}
