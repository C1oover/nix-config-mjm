{
  config,
  pkgs,
  outputs,
  ...
}:
{
  mjm.state.directories = [
    {
      directory = "/var/lib/linkding";
      user = "linkding";
      group = "linkding";
    }
  ];

  services.linkding = {
    enable = true;
    package = outputs.packages.${pkgs.system}.linkding;

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

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "linkding" ];
    ensureUsers = [
      {
        name = "linkding";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.linkding.after = [ "postgresql.service" ];

  services.consul.services.linkding = {
    inherit (config.services.linkding) port;

    checks = [
      {
        name = "linkding is ready";
        http = "http://localhost:${toString config.services.linkding.port}/health";
        interval = "15s";
        timeout = "5s";
      }
    ];
  };
}
