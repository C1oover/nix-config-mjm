{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.invidious;
in
{
  options.mjm.invidious = {
    enable = mkEnableOption "Invidious";
  };

  config = mkIf cfg.enable {
    mjm.services.invidious = {
      postgresql.enable = true;
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/private/invidious";
        user = "nobody";
        group = "nobody";
      }
    ];

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
      credentials.invidious.extra_settings = { };
    };

    mjm.spire.tunnels = {
      invidious = {
        id = "invidious";
        mode = "server";
        listen.port = 13000;
        target.port = 3000;
        allowIngress = true;
      };
    };

    services.consul.services.invidious = {
      port = 13000;

      checks.up = {
        http.path = "/";
        http.port = 3000;
      };
    };
  };
}
