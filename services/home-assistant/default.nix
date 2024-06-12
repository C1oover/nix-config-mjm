{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.home-assistant;

  port = config.services.home-assistant.config.http.server_port;
in
{
  options.mjm.home-assistant = {
    enable = mkEnableOption "home assistant";
  };

  config = mkIf cfg.enable {
    mjm.state.directories = [
      {
        directory = config.services.home-assistant.configDir;
        user = "hass";
        group = "hass";
      }
    ];
    deployment.tags = [ "svc-home-assistant" ];

    services.home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"

        "apple_tv"
        "dlna_dmr"
        "dlna_dms"
        "gitlab_ci"
        "homekit_controller"
        "hue"
        "icloud"
        "imap"
        "jellyfin"
        "lidarr"
        "matrix"
        "nut"
        "radarr"
        "roku"
        "sabnzbd"
        "sonarr"
        "tile"
        "unifi"
        "wiz"
        "zha"
      ];
      config = {
        default_config = { };
        homeassistant = {
          unit_system = "imperial"; # i'm sorry
          latitude = "!secret latitude_home";
          longitude = "!secret longitude_home";
          country = "US";
          currency = "USD";
          time_zone = "America/Denver";
          external_url = "https://home.midna.dev";
        };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            "10.0.0.3"
            "10.0.0.4"
            "2601:282:167f:3eec:dea6:32ff:fed5:d840"
            "2601:282:167f:3eec:dea6:32ff:fe96:bc05"
          ];
        };
        auth_header = {
          username_header = "Remote-User";
        };
        frontend.themes = "!include_dir_merge_named themes";
        automation = "!include automations.yaml";
        scene = "!include scenes.yaml";
        waste_collection_schedule = {
          sources = [
            {
              name = "ics";
              args.url = "webcal://recollect.a.ssl.fastly.net/api/places/1E9C397C-F80F-11E5-A7DD-59088AA306B9/services/248/events.en-US.ics?client_id=C2621F6A-AF57-11EE-813D-617B0978AF8E";
              calendar_title = "Garbage collection";
            }
          ];
        };
        sensor = [
          {
            platform = "waste_collection_schedule";
            name = "Garbage collection";
          }
        ];
        homekit = {
          filter = {
            exclude_domains = [
              "automation"
              "person"
            ];
            exclude_entity_globs = [
              "light.desk_overhead_light_*"
              "media_player.firefox*"
              "media_player.*_homepod"
              "media_player.iphone"
              "remote.*_homepod"
              "binary_sensor.55_tcl_roku_tv*"
            ];
          };
        };
        notify = [
          {
            name = "Fastmail";
            platform = "smtp";
            sender = "homeassistant@mj.midna.dev";
            recipient = "mj@midna.dev";
            server = "smtp.fastmail.com";
            port = 465;
            username = "matt@mattmoriarity.com";
            password = "!secret fastmail_password";
            encryption = "tls";
            sender_name = "Home Assistant";
          }
        ];
        adaptive_lighting = { };
        prometheus = { };
      };
      customComponents = with pkgs.home-assistant-custom-components; [
        auth-header
        waste_collection_schedule
        adaptive_lighting
      ];
    };

    systemd.tmpfiles.settings."10-home-assistant" = {
      "/var/lib/hass/themes".d = {
        user = "hass";
        group = "hass";
      };
      "/var/lib/hass/themes/catppuccin.yaml"."L+" = {
        argument = "${inputs.catppuccin-home-assistant}/themes/catppuccin.yaml";
      };
      "/var/lib/hass/secrets.yaml"."L+" = {
        argument = config.vault-secrets.templates.home-assistant-secrets.path;
      };
    };

    # homekit bridge
    networking.firewall.allowedTCPPorts = [ 21063 ];

    services.consul.services.home-assistant = {
      inherit port;

      checks = [
        {
          name = "home-assistant is ready";
          http = "http://localhost:${toString port}/manifest.json";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };

    services.avahi.enable = true;

    mjm.backups.home-assistant = {
      passwordFile = config.vault-secrets.services.home-assistant.keys.backup_password.path;
      paths = [ "/var/lib/hass/backups" ];
      backupPrepareCommand = ''
        ${pkgs.curl}/bin/curl \
          -X POST \
          http://localhost:${toString port}/api/services/backup/create \
          -H "Authorization: Bearer $(cat ${config.vault-secrets.services.home-assistant.keys.api_token.path})"
      '';
      backupCleanupCommand = ''
        rm /var/lib/hass/backups/*
      '';
    };

    vault-secrets.wantedBy = [ "home-assistant.service" ];
    vault-secrets.templates.home-assistant-secrets = {
      text = ''
        {{ with secret "kv/prod/services/home-assistant" }}
        latitude_home: {{ .Data.data.latitude_home }}
        longitude_home: {{ .Data.data.longitude_home }}
        fastmail_password: {{ .Data.data.fastmail_password }}
        {{ end }}
      '';
      owner = "hass";
    };

    vault-secrets.services.home-assistant.keys = {
      backup_password = { };
      api_token = { };
    };
  };
}
