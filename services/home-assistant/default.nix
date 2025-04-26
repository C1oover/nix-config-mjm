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

  clientId = "Ck6UhnhOFIoo8jYitELDVI7Ys93kIJ6ZGcrLI6xr1YT9PWaIYUQEjc50iqgPSlCz";
in
{
  imports = [ ./music-assistant.nix ];

  options.mjm.home-assistant = {
    enable = mkEnableOption "home assistant";
  };

  config = mkIf cfg.enable {
    mjm.services.home-assistant = {
      vault = {
        enable = true;
      };
    };
    mjm.state.directories = [
      {
        directory = config.services.home-assistant.configDir;
        user = "hass";
        group = "hass";
      }
    ];

    ingress.virtualHosts.home = {
      upstream = {
        service.name = "home-assistant";
        tls.enable = true;
      };

      enableAuthProxy = false;
    };

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
        # "icloud"
        "imap"
        "jellyfin"
        "lidarr"
        # not using yet, and it uses olm
        # "matrix"
        "music_assistant"
        "nut"
        "openweathermap"
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
          unit_system = "us_customary"; # i'm sorry
          latitude = "!secret latitude_home";
          longitude = "!secret longitude_home";
          country = "US";
          currency = "USD";
          time_zone = "America/Denver";
          external_url = "https://home.midna.dev";
        };
        http = {
          server_host = [
            "127.0.0.1"
            "::1"
          ];
          server_port = 18123;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };
        auth_oidc = {
          client_id = clientId;
          client_secret = "!secret oidc_client_secret";
          discovery_url = "https://auth.midna.dev/.well-known/openid-configuration";
          display_name = "Authelia";
          features.automatic_user_linking = true;
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
        rest = [
          {
            resource = "http://localhost:28982/api/documents/";
            params.tags__name__iexact = "inbox";
            headers.Authorization = "!secret paperless_authorization";
            sensor = [
              {
                name = "Paperless inbox document count";
                value_template = "{{ value_json.count }}";
              }
            ];
          }
        ];
      };
      customComponents = with pkgs.home-assistant-custom-components; [
        auth_oidc
        waste_collection_schedule
        adaptive_lighting
      ];
    };

    mjm.spire.tunnels = {
      home-assistant = {
        mode = "server";
        listen.port = 8123;
        target.port = 18123;
        allowIngress = true;
        allowConsul = true;
        allowedServices = [
          "backups"
        ];
      };
      home-assistant-paperless = {
        mode = "client";
        listen.port = 28982;
        target.service = "paperless";
        target.port = 28981;
      };
      backup-home-assistant = {
        mode = "client";
        listen.socket = "/run/backup-home-assistant.sock";
        target.port = 8123;
        service = "home-assistant";
      };
      consul-home-assistant = {
        mode = "client";
        listen.socket = "/run/consul-checks/home-assistant.sock";
        target.port = 8123;
        service = "home-assistant";
      };
    };

    mjm.authelia.oidcClients.hass = {
      name = "Home Assistant";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$0IiDX4VOL96OzjoCAdNnZg$iyajs99yFezP4fPw4nH5vnqfOoN04jkN7eVZhNPPweM";
      requirePkce = true;
      redirectUris = [ "https://home.midna.dev/auth/oidc/callback" ];
      scopes = [
        "openid"
        "profile"
        "groups"
      ];
      tokenEndpointAuthMethod = "client_secret_post";
    };

    systemd.services.home-assistant-secrets = {
      wantedBy = [ "home-assistant.service" ];
      before = [ "home-assistant.service" ];
      path = [ pkgs.systemd ];
      startLimitIntervalSec = 0;
      script = ''
        cat > /run/home-assistant-secrets/secrets.yaml <<EOF
        latitude_home: $(systemd-creds cat home-assistant_latitude_home)
        longitude_home: $(systemd-creds cat home-assistant_longitude_home)
        fastmail_password: $(systemd-creds cat home-assistant_fastmail_password)
        paperless_authorization: Token $(systemd-creds cat home-assistant_paperless_token)
        oidc_client_secret: $(systemd-creds cat home-assistant_managed__oidc_client_secret)
        EOF
      '';
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = 5;
        RemainAfterExit = true;
        User = "hass";
        Group = "hass";
        PrivateNetwork = true;
        PrivateTmp = true;
        RuntimeDirectory = "home-assistant-secrets";
        RuntimeDirectoryMode = "0700";
        LoadCredential = [
          "home-assistant_latitude_home:/run/home-assistant-creds.sock"
          "home-assistant_longitude_home:/run/home-assistant-creds.sock"
          "home-assistant_fastmail_password:/run/home-assistant-creds.sock"
          "home-assistant_paperless_token:/run/home-assistant-creds.sock"
          "home-assistant_managed__oidc_client_secret:/run/home-assistant-creds.sock"
        ];
      };
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
        argument = "/run/home-assistant-secrets/secrets.yaml";
      };
    };

    # homekit bridge
    networking.firewall.allowedTCPPorts = [ 21063 ];

    services.consul.services.home-assistant = {
      port = 8123;

      checks.up = {
        http.path = "/manifest.json";
        http.socket = "/run/consul-checks/home-assistant.sock";
      };
    };

    services.avahi.enable = true;

    mjm.backups.home-assistant = {
      paths = [ "/var/lib/hass/backups" ];
      backupPrepareCommand = ''
        ${pkgs.curl}/bin/curl \
          -X POST \
          --unix-socket=/run/backup-home-assistant.sock \
          http://home-assistant.service.consul/api/services/backup/create \
          -H "Authorization: Bearer $(cat $CREDENTIALS_DIRECTORY/home-assistant_api_token)"
      '';
      backupCleanupCommand = ''
        rm /var/lib/hass/backups/*
      '';
    };
    systemd.services.restic-backups-home-assistant = {
      serviceConfig.LoadCredential = [ "home-assistant_api_token:/run/home-assistant-creds.sock" ];
    };

    # these are too fragile i think
    # deployment.tests = {
    #   inherit (pkgs.nixosTests) home-assistant;
    # };
  };
}
