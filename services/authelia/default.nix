{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.authelia;
in
{
  options.mjm.authelia = {
    enable = mkEnableOption "authelia";
  };

  imports = [ ./lldap.nix ];

  config = mkIf cfg.enable {
    mjm.services.authelia = {
      postgresql = {
        enable = true;
        databases = [ "authelia-main" ];
      };
      vault = {
        enable = true;
        loadedBy = [ "authelia-main" ];
        keys = {
          jwt_secret = { };
          hmac_secret = { };
          jwt_private_key = { };
          ldap_password = { };
          session_secret = { };
          smtp_password = { };
          storage_encryption_key = { };
        };
      };
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/redis-authelia";
        user = "redis-authelia";
        group = "redis-authelia";
      }
    ];

    services.authelia.instances.main = {
      enable = true;
      settings = {
        theme = "auto";
        default_redirection_url = "https://home.midna.dev/";
        default_2fa_method = "webauthn";
        server.address = "tcp://:9091";
        telemetry.metrics = {
          enabled = true;
          address = "tcp://0.0.0.0:9959";
        };
        webauthn.display_name = "Homelab";
        authentication_backend.ldap = {
          implementation = "custom";
          url = "ldap://localhost:3890";
          timeout = "5s";
          start_tls = false;
          base_dn = "dc=home,dc=mattmoriarity,dc=com";
          username_attribute = "uid";
          additional_users_dn = "ou=people";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          additional_groups_dn = "ou=groups";
          groups_filter = "(member={dn})";
          group_name_attribute = "cn";
          mail_attribute = "mail";
          display_name_attribute = "displayName";
          user = "uid=service,ou=people,dc=home,dc=mattmoriarity,dc=com";
        };
        access_control = {
          default_policy = "two_factor";
          rules = import ./rules.nix;
        };
        session.domain = "midna.dev";
        session.redis.host = "${config.services.redis.servers.authelia.unixSocket}";
        storage.postgres = {
          host = "/run/postgresql";
          port = 5432;
          database = "authelia-main";
          username = "authelia-main";
          password = "authelia-main";
        };
        notifier.smtp = {
          host = "smtp.fastmail.com";
          port = 587;
          username = "matt@mattmoriarity.com";
          sender = "Authelia <admin@mattmoriarity.com>";
        };
        identity_providers.oidc.clients = import ./oidc-clients.nix;
      };
      secrets.manual = true;
      environmentVariables = {
        AUTHELIA_JWT_SECRET_FILE = "%d/authelia_jwt_secret";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "%d/authelia_hmac_secret";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = "%d/authelia_jwt_private_key";
        AUTHELIA_SESSION_SECRET_FILE = "%d/authelia_session_secret";
        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/authelia_storage_encryption_key";
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/authelia_ldap_password";
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "%d/authelia_smtp_password";
      };
    };

    systemd.services.authelia-main = {
      after = [
        "lldap.service"
        "redis-authelia.service"
        "postgresql.service"
      ];
      serviceConfig = {
        SupplementaryGroups = [ config.services.redis.servers.authelia.user ];
      };
    };

    services.redis.servers.authelia.enable = true;

    networking.firewall.allowedTCPPorts = [
      9091
      9959
    ];

    services.consul.services.authelia = {
      port = 9091;

      meta = {
        metrics_path = "/metrics";
        metrics_port = "9959";
      };

      checks = [
        {
          name = "authelia is ready";
          http = "http://localhost:9091/api/health";
          interval = "30s";
          timeout = "5s";
        }
      ];
    };

    ingress.virtualHosts = {
      auth = {
        upstream.service.name = "authelia";

        enableAuthProxy = false;
        useIPv4Proxy = true;
        recommendedProxySettings = false;

        extraServerConfig = ''
          location /api/verify {
            proxy_pass http://auth;
          }
        '';

        extraLocationConfig = ''
          ## Headers
          proxy_set_header Host $host;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
          proxy_set_header X-Forwarded-Uri $request_uri;
          proxy_set_header X-Forwarded-Ssl on;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header Connection "";

          ## Basic Proxy Configuration
          client_body_buffer_size 128k;
          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; ## Timeout if the real server is dead.
          proxy_redirect  http://  $scheme://;
          proxy_cache_bypass $cookie_session;
          proxy_no_cache $cookie_session;
          proxy_buffers 64 256k;

          ## Trusted Proxies Configuration
          ## Please read the following documentation before configuring this:
          ##     https://www.authelia.com/integration/proxies/nginx/#trusted-proxies
          # set_real_ip_from 10.0.0.0/8;
          # set_real_ip_from 172.16.0.0/12;
          # set_real_ip_from 192.168.0.0/16;
          # set_real_ip_from fc00::/7;
          set_real_ip_from 10.0.0.2;
          set_real_ip_from 10.0.0.3;
          set_real_ip_from 10.0.0.4;
          real_ip_header X-Forwarded-For;
          real_ip_recursive on;

          ## Advanced Proxy Configuration
          send_timeout 5m;
          proxy_read_timeout 360;
          proxy_send_timeout 360;
          proxy_connect_timeout 360;
        '';
      };

      users = {
        upstream.service.name = "lldap";
        enableAuthProxy = false;
      };
    };
  };
}
