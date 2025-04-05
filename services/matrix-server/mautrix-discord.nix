{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.matrix-server;

  configFormat = pkgs.formats.yaml { };
  configFile = configFormat.generate "mautrix-discord-config.yaml" {
    homeserver = {
      address = "http://localhost:6166";
      public_address = "https://chat.midna.dev";
      domain = "midna.dev";
    };
    appservice = {
      address = "http://127.0.0.1:29334";
      hostname = "127.0.0.1";
      port = port;
      database = {
        type = "postgres";
        uri = "postgres:///mautrix-discord?host=/run/postgresql";
      };
      id = "discord";
      bot.username = "discordbot";
      bot.displayname = "Discord Bridge Bot";
    };
    bridge = {
      backfill.enable = true;
      permissions = {
        "midna.dev" = "user";
        "@mjm:midna.dev" = "admin";
      };
    };
  };
  settingsFile = "/var/lib/mautrix-discord/config.yml";
  registrationFile = "/var/lib/mautrix-discord/registration.yml";

  port = 29334;
in
{
  options.mjm.matrix-server.bridges.discord = {
    enable = mkEnableOption "discord bridge" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.bridges.discord.enable) {
    mjm.services.matrix-server.postgresql = {
      enable = true;
      databases = [ "mautrix-discord" ];
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/mautrix-discord";
        user = "mautrix-discord";
        group = "mautrix-discord";
        mode = "0700";
      }
    ];

    systemd.services.mautrix-discord = {
      description = "mautrix-discord bridge";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.ffmpeg-full ];
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
          ${pkgs.mautrix-discord}/bin/mautrix-discord \
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
        ExecStart = "${pkgs.mautrix-discord}/bin/mautrix-discord -c ${settingsFile} -r ${registrationFile}";
        User = "mautrix-discord";
        Group = "mautrix-discord";
        StateDirectory = "mautrix-discord";
        WorkingDirectory = "/var/lib/mautrix-discord";
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

    users.users.mautrix-discord = {
      isSystemUser = true;
      group = "mautrix-discord";
      home = "/var/lib/mautrix-discord";
    };
    users.groups.mautrix-discord = { };

    services.consul.services.mautrix-discord = {
      inherit port;

      checks.up = {
        http.path = "/_matrix/mau/ready";
      };
    };
  };
}
