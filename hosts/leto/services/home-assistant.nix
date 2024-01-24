{
  pkgs,
  config,
  outputs,
  ...
}: let
  port = config.services.home-assistant.config.http.server_port;
in {
  # ugh
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"

      "apple_tv"
      "jellyfin"
      "homekit_controller"
      "hue"
      "icloud"
      "roku"
      "unifi"
    ];
    config = {
      default_config = {};
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
          exclude_domains = ["automation" "person"];
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
      adaptive_lighting = {};
    };
    customComponents = with pkgs.home-assistant-custom-components; [
      outputs.packages.${pkgs.system}.hass-auth-header
      waste_collection_schedule
      adaptive_lighting
    ];
  };

  # homekit bridge
  networking.firewall.allowedTCPPorts = [21063];

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

  services.restic.backups.home-assistant = {
    initialize = true;
    repository = "s3:http://garage.service.consul:3902/restic-backups/home-assistant";
    passwordFile = config.age.secrets."home-assistant-backup-password".path;
    environmentFile = config.age.secrets."backup.env".path;
    paths = [
      "/var/lib/hass/backups"
    ];
    backupPrepareCommand = ''
      ${pkgs.curl}/bin/curl -XPOST http://localhost:${toString port}/api/services/backup/create -H "Authorization: Bearer $(cat ${config.age.secrets."home-assistant-token".path})"
    '';
    backupCleanupCommand = ''
      rm /var/lib/hass/backups/*
    '';
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
  };

  age.secrets."backup.env".file = ../../../secrets/restic-backup-env.age;
  age.secrets."home-assistant-backup-password".file = ../../../secrets/home-assistant-backup-password.age;
  age.secrets."home-assistant-token".file = ../../../secrets/home-assistant-token.age;
}
