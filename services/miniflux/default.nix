{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.mjm.miniflux;
in
{
  options.mjm.miniflux = {
    enable = mkEnableOption "miniflux";
  };

  config = mkIf cfg.enable {
    mjm.services.miniflux = { };
    mjm.postgresql.enable = true;

    ingress.virtualHosts.feeds = {
      upstream.service.name = "miniflux";
      useIPv4Proxy = true;
    };

    services.miniflux = {
      enable = true;
      config = {
        LISTEN_ADDR = "[::]:9999";
        BASE_URL = "https://feeds.midna.dev/";
        METRICS_COLLECTOR = 1;
        METRICS_ALLOWED_NETWORKS = "127.0.0.1/8,10.0.0.0/16,2601:282:167f:d062::/64";
        AUTH_PROXY_HEADER = "Remote-User";
        AUTH_PROXY_USER_CREATION = 1;
        CREATE_ADMIN = mkForce 0;
      };
      adminCredentialsFile = pkgs.writeText "miniflux-creds" "";
    };

    networking.firewall.allowedTCPPorts = [ 9999 ];

    services.consul.services.miniflux = {
      port = 9999;
      metrics.enable = true;

      checks.up = {
        http.path = "/healthcheck";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) miniflux;
    };
  };
}
