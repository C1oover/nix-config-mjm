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
    mjm.services.atuin = { };

    ingress.virtualHosts.atuin = {
      upstream.service.name = "atuin";
      enableAuthProxy = false;
    };

    services.atuin = {
      enable = true;
      host = "::";
      openFirewall = true;
    };

    services.consul.services.atuin = {
      inherit (config.services.atuin) port;

      checks.up = {
        http.path = "/";
      };
    };
  };
}
