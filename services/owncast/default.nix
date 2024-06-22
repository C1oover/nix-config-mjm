{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.owncast;
in
{
  options.mjm.owncast = {
    enable = mkEnableOption "owncast";
  };

  config = mkIf cfg.enable {
    deployment.tags = [ "svc-owncast" ];
    mjm.state.directories = [
      {
        directory = config.services.owncast.dataDir;
        inherit (config.services.owncast) user group;
      }
    ];

    services.owncast = {
      enable = true;
      openFirewall = true;
      listen = "0.0.0.0";
      port = 9090;
    };

    services.consul.services.owncast = {
      inherit (config.services.owncast) port;

      checks = [
        {
          name = "owncast is ready";
          http = "http://localhost:${toString config.services.owncast.port}/api/config";
          interval = "15s";
          timeout = "5s";
        }
        {
          name = "owncast rtmp is ready";
          tcp = "localhost:${toString config.services.owncast.rtmp-port}";
          interval = "15s";
          timeout = "5s";
        }
      ];
    };
  };
}
