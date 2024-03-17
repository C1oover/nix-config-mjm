{
  pkgs,
  outputs,
  config,
  ...
}:
let
  pkg = outputs.packages.${pkgs.system}.mautrix-slack;

  configFormat = pkgs.formats.yaml { };
  configFile = configFormat.generate "mautrix-slack-config.yaml" {
    homeserver = {
      address = "http://localhost:6167";
      domain = "midna.dev";
    };
    appservice = {
      address = "http://127.0.0.1:29335";
      hostname = "127.0.0.1";
      port = 29335;
      database = {
        type = "postgres";
        uri = "postgres:///mautrix-slack?host=/run/postgresql";
      };
      id = "slack";
      bot.username = "slackbot";
      bot.displayname = "Slack Bridge Bot";
    };
    bridge = {
      backfill.enable = true;
      permissions = {
        "midna.dev" = "user";
        "@mjm:midna.dev" = "admin";
      };
    };
  };
  settingsFile = "/var/lib/mautrix-slack/config.yml";
  registrationFile = "/var/lib/mautrix-slack/registration.yml";
in
{
  mjm.postgresql.enable = true;
  mjm.state.directories = [
    {
      directory = "/var/lib/mautrix-slack";
      user = "mautrix-slack";
      group = "mautrix-slack";
      mode = "0700";
    }
  ];

  systemd.services.mautrix-slack = {
    description = "mautrix-slack bridge";
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      # substitute the settings file by environment variables
      # in this case read from EnvironmentFile
      test -f '${settingsFile}' && rm -f '${settingsFile}'
      old_umask=$(umask)
      umask 0177
      ${pkgs.envsubst}/bin/envsubst \
        -o '${settingsFile}' \
        -i '${configFile}'
      umask $old_umask

      # generate the appservice's registration file if absent
      if [ ! -f '${registrationFile}' ]; then
        ${pkg}/bin/mautrix-slack \
          --generate-registration \
          --config='${settingsFile}' \
          --registration='${registrationFile}'
      fi
      chmod 640 ${registrationFile}

      umask 0177
      ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
        | .[0].appservice.hs_token = .[1].hs_token
        | .[0]' '${settingsFile}' '${registrationFile}' \
        > '${settingsFile}.tmp'
      mv '${settingsFile}.tmp' '${settingsFile}'
      umask $old_umask
    '';
    restartTriggers = [ configFile ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkg}/bin/mautrix-slack -c ${settingsFile} -r ${registrationFile}";
      User = "mautrix-slack";
      Group = "mautrix-slack";
      StateDirectory = "mautrix-slack";
      WorkingDirectory = "/var/lib/mautrix-slack";
      Restart = "on-failure";
      RestartSec = "30s";

      NoNewPrivileges = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      LockPersonality = true;
      ProtectKernelLogs = true;
      ProtectKernelTunables = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
      PrivateUsers = true;
      ProtectClock = true;
      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = "@system-service";
    };
  };

  users.users.mautrix-slack = {
    isSystemUser = true;
    group = "mautrix-slack";
    home = "/var/lib/mautrix-slack";
  };
  users.groups.mautrix-slack = { };

  services.postgresql = {
    ensureDatabases = [ "mautrix-slack" ];
    ensureUsers = [
      {
        name = "mautrix-slack";
        ensureDBOwnership = true;
      }
    ];
  };
}
