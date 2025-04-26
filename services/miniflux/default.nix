{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.mjm.miniflux;

  clientId = "4dVtVDFB6wqBTqqE1hJzVe2shJDaMiEH3wY9BjN9IQ44lrnFmcxiOwzdBDHmk3zB";
  redirectUri = "https://feeds.midna.dev/oauth2/oidc/callback";
in
{
  options.mjm.miniflux = {
    enable = mkEnableOption "miniflux";
  };

  config = mkIf cfg.enable {
    mjm.services.miniflux = {
      vault = {
        enable = true;
      };
    };
    mjm.postgresql.enable = true;

    ingress.virtualHosts.feeds = {
      upstream = {
        service.name = "miniflux";
        tls.enable = true;
      };

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.miniflux = {
      enable = true;
      config = {
        LISTEN_ADDR = "/run/miniflux/server.sock";
        BASE_URL = "https://feeds.midna.dev/";
        METRICS_COLLECTOR = 1;
        METRICS_ALLOWED_NETWORKS = "127.0.0.1/8,10.0.0.0/16,${config.mjm.ipv6Prefix}::/64";
        CREATE_ADMIN = mkForce 0;
        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID = clientId;
        OAUTH2_CLIENT_SECRET_FILE = "%d/miniflux_managed__oidc_client_secret";
        OAUTH2_REDIRECT_URL = redirectUri;
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.midna.dev";
        OAUTH2_USER_CREATION = 1;
      };
    };

    systemd.services.miniflux = {
      serviceConfig.LoadCredential = [ "miniflux_managed__oidc_client_secret:/run/miniflux-creds.sock" ];
      serviceConfig.RuntimeDirectoryMode = mkForce "0755";
    };

    mjm.authelia.oidcClients.miniflux = {
      name = "Miniflux";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$F6tAZnVxae+QgvGjCC6GhQ$tVXggATlvY5qpsMut62Ap5B8RcRPi4HPZwrfz02uJ7Q";
      requirePkce = true;
      redirectUris = [ redirectUri ];
    };

    mjm.spire.tunnels = {
      miniflux = {
        mode = "server";
        listen.port = 9999;
        target.socket = "/run/miniflux/server.sock";
        allowIngress = true;
        allowMetrics = true;
      };
    };

    services.consul.services.miniflux = {
      port = 9999;

      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/healthcheck";
        http.socket = "/run/miniflux/server.sock";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) miniflux;
    };
  };
}
