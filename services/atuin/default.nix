{
  pkgs,
  config,
  lib,
  ...
}:
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
    mjm.postgresql.enable = true;

    ingress.virtualHosts.atuin = {
      upstream = {
        service.name = "atuin";
        tls.enable = true;
      };

      enableAuthProxy = false;
    };

    services.atuin = {
      enable = true;
      host = "::1";
      port = 18888;
    };

    mjm.spire.tunnels = {
      atuin = {
        id = "atuin";
        mode = "server";
        listen.port = 8888;
        target.port = 18888;
        allowIngress = true;
      };
    };

    services.consul.services.atuin = {
      port = 8888;

      checks.up = {
        http.path = "/";
        http.port = 18888;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) atuin;
    };
  };
}
