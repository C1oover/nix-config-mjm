{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.services.invidious = {
      postgresql.enable = true;
      vault = {
        enable = true;
      };
    };
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    ingress.virtualHosts.yt = {
      upstream = {
        service.name = "invidious";
        tls.enable = true;
      };

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.invidious = {
      enable = true;
      domain = "yt.midna.dev";
      address = "::1";
      port = 3000;
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
      extraSettingsFile = "/run/credentials/invidious.service/invidious_extra_settings";

      sig-helper.enable = true;
    };

    systemd.services.invidious = {
      networkNamespace = "invidious";
      serviceConfig.LoadCredential = [ "invidious_extra_settings:/run/invidious-creds.sock" ];
    };
    systemd.services.invidious-sig-helper.networkNamespace = "invidious";

    mjm.spire.tunnels = {
      invidious = {
        mode = "server";
        listen.port = 3000;
        target.port = 3000;
        target.namespace = "invidious";
        allowIngress = true;
        allowConsul = true;
      };
      consul-invidious = {
        mode = "client";
        listen.socket = "/run/consul-checks/invidious.sock";
        target.port = 3000;
        service = "invidious";
      };
    };

    services.consul.services.invidious = {
      port = 3000;

      checks.up = {
        http.path = "/";
        http.socket = "/run/consul-checks/invidious.sock";
      };
    };
  };
}
