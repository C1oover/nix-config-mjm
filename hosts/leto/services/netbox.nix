{ config, pkgs, ... }:
{
  services.netbox = {
    enable = true;
    package = pkgs.netbox_3_7;
    listenAddress = "[::]";
    settings = {
      ALLOWED_HOSTS = [
        "netbox.midna.dev"
        "netbox.service.consul"
        "10.0.2.41"
      ];
      CORS_ORIGIN_ALLOW_ALL = false;
      CORS_ORIGIN_WHITELIST = [ "https://netbox.midna.dev" ];
      CSRF_TRUSTED_ORIGINS = [
        "https://netbox.midna.dev"
        "http://netbox.service.consul:8000"
      ];
      METRICS_ENABLED = true;
      REMOTE_AUTH_ENABLED = true;
      REMOTE_AUTH_BACKEND = "netbox.authentication.RemoteUserBackend";
      REMOTE_AUTH_HEADER = "HTTP_REMOTE_USER";
      REMOTE_AUTH_AUTO_CREATE_USER = true;
      REMOTE_AUTH_GROUP_HEADER = "HTTP_REMOTE_GROUPS";
      REMOTE_AUTH_GROUP_SYNC_ENABLED = true;
      REMOTE_AUTH_GROUP_SEPARATOR = ",";
      REMOTE_AUTH_SUPERUSER_GROUPS = [ "admins" ];
      REMOTE_AUTH_STAFF_GROUPS = [ "admins" ];
    };
    secretKeyFile = "/run/vault-secrets/netbox-secret-key";
  };

  systemd.services.netbox.after = [ "render-vault-secrets.service" ];

  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    defaultHTTPListenPort = 8000;
    upstreams = {
      netbox = {
        servers = {
          "127.0.0.1:${toString config.services.netbox.port}" = { };
        };
      };
    };
    virtualHosts."netbox" = {
      serverName = "_";
      default = true;
      locations."/static/" = {
        alias = config.services.netbox.settings.STATIC_ROOT + "/";
      };
      locations."/" = {
        proxyPass = "http://netbox";
        recommendedProxySettings = true;
      };
    };
  };

  users.users.nginx.extraGroups = [ "netbox" ];

  networking.firewall.allowedTCPPorts = [ config.services.nginx.defaultHTTPListenPort ];

  services.consul.services.netbox = {
    port = config.services.nginx.defaultHTTPListenPort;
    meta.metrics_path = "/metrics";
  };
}
