{
  pkgs,
  outputs,
  ...
}: let
  inherit (outputs.packages.${pkgs.system}) linkding uwsgi;

  env = {
    LD_SUPERUSER_NAME = "mjm";
    LD_ENABLE_AUTH_PROXY = "True";
    LD_AUTH_PROXY_USERNAME_HEADER = "HTTP_REMOTE_USER";
    LD_AUTH_PROXY_LOGOUT_URL = "https://auth.midna.dev/logout";
    LD_CSRF_TRUSTED_ORIGINS = "https://links.midna.dev";
    LD_DB_ENGINE = "postgres";
    LD_DB_DATABASE = "linkding";
    LD_DB_HOST = "postgresql.service.consul";
  };

  uwsgiCfg = pkgs.writeText "linkding-uwsgi.ini" ''
    [uwsgi]
    module = siteroot.wsgi:application
    env = DJANGO_SETTINGS_MODULE=siteroot.settings.prod
    static-map = /static=${linkding}/lib/linkding/static
    static-map = /static=/var/lib/linkding/favicons
    processes = 2
    threads = 2
    vacuum = True
    stats = 127.0.0.1:9191
    buffer-size = 8192
    die-on-term = true

    if-env = LD_CONTEXT_PATH
    static-map = /%(_)static=static
    static-map = /%(_)static=data/favicons
    endif =

    if-env = LD_REQUEST_TIMEOUT
    http-timeout = %(_)
    socket-timeout = %(_)
    harakiri = %(_)
    endif =

    if-env = LD_LOG_X_FORWARDED_FOR
    log-x-forwarded-for = %(_)
    endif =
  '';
in {
  users.users.linkding = {
    isSystemUser = true;
    group = "linkding";
    home = "/var/lib/linkding";
  };

  users.groups.linkding = {};

  systemd.services.linkding = {
    description = "Linkding bookmarks manager";
    wantedBy = ["multi-user.target"];
    preStart = ''
      ${linkding}/bin/linkding migrate
      ${linkding}/bin/linkding enable_wal
      (cd $STATE_DIRECTORY && ${linkding}/bin/linkding generate_secret_key)
      ${linkding}/bin/linkding create_initial_superuser
    '';
    script = ''
      exec ${uwsgi}/bin/uwsgi --http :7090 ${uwsgiCfg}
    '';
    serviceConfig = {
      User = "linkding";
      Restart = "on-failure";
      StateDirectory = "linkding";
      EnvironmentFile = "/run/secrets/linkding/db.env";
      WorkingDirectory = "${linkding}/lib/linkding";
    };
    environment =
      env
      // {
        PYTHONPATH = "${linkding.python.pkgs.makePythonPath linkding.propagatedBuildInputs}:${linkding}/lib/linkding";
      };
  };

  systemd.services.linkding-tasks = {
    description = "Linkding background task worker";
    wantedBy = ["multi-user.target"];
    preStart = ''
      mkdir -p /var/lib/linkding/favicons
    '';
    script = ''
      ${linkding}/bin/linkding clean_tasks
      exec ${linkding}/bin/linkding process_tasks
    '';
    serviceConfig = {
      User = "linkding";
      Restart = "on-failure";
      StateDirectory = "linkding";
      EnvironmentFile = "/run/secrets/linkding/db.env";
    };
    environment = env;
  };

  networking.firewall.allowedTCPPorts = [7090];

  services.consul.services.linkding = {
    port = 7090;

    checks = [
      {
        name = "linkding is ready";
        http = "http://localhost:7090/health";
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
      command = "systemctl restart linkding.service";
    }
  ];
}
