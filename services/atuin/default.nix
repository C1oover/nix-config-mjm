{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.atuin;
in
{
  options.mjm.atuin = {
    enable = mkEnableOption "atuin";
  };

  config = mkIf cfg.enable {
    deployment.tags = [ "svc-atuin" ];

    services.atuin = {
      enable = true;
      host = "::";
      openFirewall = true;
    };

    services.consul.services.atuin =
      let
        inherit (config.services.atuin) port;
      in
      {
        inherit port;

        checks = [
          {
            name = "atuin is ready";
            http = "http://localhost:${toString port}/";
            interval = "15s";
            timeout = "5s";
          }
        ];
      };
  };
}
