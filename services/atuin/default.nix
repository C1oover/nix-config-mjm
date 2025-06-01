{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.atuin;
in
{
  options.cloover.atuin = {
    enable = mkEnableOption "atuin";
  };

  config = mkIf cfg.enable {
    cloover.services.atuin = { };
    cloover.postgresql.enable = true;

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

    cloover.spire.tunnels = {
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
