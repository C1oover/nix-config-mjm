{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mapAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    ;
  cfg = config.mjm.authelia;

  secrets = {
    AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "ldap_password";
    AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "hmac_secret";
    AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = "jwt_private_key";
    AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "jwt_secret";
    AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "smtp_password";
    AUTHELIA_SESSION_SECRET_FILE = "session_secret";
    AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "storage_encryption_key";
  };

  credentials = mapAttrs' (_: v: {
    name = v;
    value = { };
  }) secrets;
  secretEnvVars = mapAttrs (_: key: "%d/authelia_${key}") secrets;
in
{
  options.mjm.authelia = {
    enable = mkEnableOption "authelia";
  };

  imports = [
    ./lldap.nix
    ./oidc-clients.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.authelia = {
      postgresql = {
        enable = true;
        databases = [ "authelia-main" ];
      };
      vault.enable = true;
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
        default_2fa_method = "webauthn";
        server.address = "tcp://127.0.0.1:9191";
        telemetry.metrics = {
          enabled = true;
          address = "tcp://0.0.0.0:9959";
        };
        webauthn = {
          enable_passkey_login = true;
          experimental_enable_passkey_uv_two_factors = true;
          display_name = "Homelab";
          attestation_conveyance_preference = "direct";
          metadata = {
            enabled = true;
            validate_entry = false;
          };
        };
        authentication_backend.ldap = {
          implementation = "lldap";
          address = "ldap://localhost:3890";
          timeout = "5s";
          start_tls = false;
          base_dn = "dc=home,dc=mattmoriarity,dc=com";
          attributes = {
            username = "uid";
            mail = "mail";
            group_name = "cn";
            member_of = "memberOf";
            display_name = "displayName";
          };
          user = "uid=service,ou=people,dc=home,dc=mattmoriarity,dc=com";
        };
        definitions = {
          network.home = [
            "10.0.0.0/8"
            "${config.mjm.ipv6Prefix}::/64"
          ];
        };
        access_control = {
          default_policy = "two_factor";
          rules = import ./rules.nix;
        };
        session.cookies = [
          {
            domain = "midna.dev";
            authelia_url = "https://auth.midna.dev";
            default_redirection_url = "https://launch.midna.dev";
          }
        ];
        session.redis.host = "${config.services.redis.servers.authelia.unixSocket}";
        storage.postgres = {
          address = "unix:///run/postgresql";
          database = "authelia-main";
          username = "authelia-main";
          password = "authelia-main";
        };
        notifier.smtp = {
          address = "submission://smtp.fastmail.com:587";
          username = "matt@mattmoriarity.com";
          sender = "Authelia <admin@mattmoriarity.com>";
        };
      };
      secrets.manual = true;
      environmentVariables = secretEnvVars;
    };

    systemd.services.authelia-main = {
      after = [
        "lldap.service"
        "redis-authelia.service"
        "postgresql.service"
      ];
      credentials.authelia = credentials;
      serviceConfig = {
        SupplementaryGroups = [ config.services.redis.servers.authelia.user ];
      };
    };

    services.redis.servers.authelia.enable = true;

    mjm.spire.tunnels.authelia = {
      mode = "server";
      listen.port = 9091;
      target.port = 9191;
      allowIngress = true;
    };

    networking.firewall.allowedTCPPorts = [
      9959
    ];

    services.consul.services.authelia = {
      port = 9091;

      metrics.enable = true;
      metrics.port = 9959;

      checks.up = {
        http.path = "/api/health";
        http.port = 9191;
        intervalSeconds = 30;
      };
    };

    ingress.virtualHosts.auth = {
      upstream = {
        service.name = "authelia";
        tls.enable = true;
      };

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) authelia;
    };
  };
}
