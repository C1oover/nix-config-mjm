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
      port = 8888;
    };

    systemd.services.atuin = {
      bindsTo = [ "netns-bridge@atuin.service" ];
      after = [ "netns-bridge@atuin.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/atuin";
      };
    };

    mjm.spire.tunnels = {
      atuin = {
        mode = "server";
        listen.port = 8888;
        target.port = 8888;
        target.namespace = "atuin";
        allowIngress = true;
        allowConsul = true;
      };
      consul-atuin = {
        mode = "client";
        listen.socket = "/run/consul-checks/atuin.sock";
        target.port = 8888;
        service = "atuin";
      };
    };

    services.consul.services.atuin = {
      inherit (config.services.atuin) port;

      checks.up = {
        http.path = "/";
        http.socket = "/run/consul-checks/atuin.sock";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) atuin;
    };
  };
}
