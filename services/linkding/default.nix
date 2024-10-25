{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.linkding;
in
{
  options.mjm.linkding = {
    enable = mkEnableOption "linkding";
  };

  config = mkIf cfg.enable {
    mjm.services.linkding = {
      postgresql.enable = true;
    };
    mjm.state.services = [ "linkding" ];

    ingress.virtualHosts.links = {
      upstream.service.name = "linkding";
      useIPv4Proxy = true;
    };

    services.linkding = {
      enable = true;

      address = "";
      port = 7090;
      openFirewall = true;

      settings = {
        LD_SUPERUSER_NAME = "mjm";
        LD_ENABLE_AUTH_PROXY = "True";
        LD_AUTH_PROXY_USERNAME_HEADER = "HTTP_REMOTE_USER";
        LD_AUTH_PROXY_LOGOUT_URL = "https://auth.midna.dev/logout";
        LD_CSRF_TRUSTED_ORIGINS = "https://links.midna.dev";
        LD_DB_ENGINE = "postgres";
        LD_DB_DATABASE = "linkding";
        LD_DB_HOST = "/run/postgresql";
        LD_DB_USER = "linkding";
      };
    };

    systemd.services.linkding.after = [ "postgresql.service" ];

    services.consul.services.linkding = {
      inherit (config.services.linkding) port;

      checks.up = {
        http.path = "/health";
      };
    };
  };
}
