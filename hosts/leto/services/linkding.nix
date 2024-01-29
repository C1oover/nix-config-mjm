{
  config,
  pkgs,
  outputs,
  ...
}: {
  services.linkding = {
    enable = true;
    package = outputs.packages.${pkgs.system}.linkding;
    uwsgi.package = outputs.packages.${pkgs.system}.uwsgi;

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
      LD_DB_HOST = "postgresql.service.consul";
    };

    environmentFile = "/run/secrets/linkding/db.env";
  };

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

  systemd.tmpfiles.settings."10-secrets"."/run/secrets/linkding".d = {
    mode = "0700";
    user = "linkding";
    group = "linkding";
  };

  services.vault-agent.instances.main.templates = [
    {
      contents = ''
        {{ with secret "database/creds/linkding" }}
        LD_DB_USER={{ .Data.username }}
        LD_DB_PASSWORD={{ .Data.password }}
        {{ end }}
      '';
      destination = "/run/secrets/linkding/db.env";
      command = "systemctl restart linkding.service linkding-tasks.service";
    }
  ];
}
