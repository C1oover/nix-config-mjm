{ config, ... }:
let
  inherit (config.services.authelia.instances.main) user group;
in
{
  services.authelia.instances.main = {
    enable = true;
    settings = {
      default_redirection_url = "https://home.midna.dev/";
      default_2fa_method = "webauthn";
      server.host = "::";
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
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-jwt-secret".path;
      oidcHmacSecretFile = config.age.secrets."authelia-hmac-secret".path;
      oidcIssuerPrivateKeyFile = config.age.secrets."authelia-jwt-private-key".path;
      sessionSecretFile = config.age.secrets."authelia-session-secret".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-storage-encryption-key".path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
        config.age.secrets."authelia-ldap-password".path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."authelia-smtp-password".path;
    };
  };

  systemd.services.authelia-main = {
    after = [
      "lldap.service"
      "redis-authelia.service"
      "postgresql.service"
    ];
    serviceConfig.SupplementaryGroups = [ config.services.redis.servers.authelia.user ];
  };

  services.redis.servers.authelia.enable = true;
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "authelia-main" ];
    ensureUsers = [
      {
        name = "authelia-main";
        ensureDBOwnership = true;
      }
    ];
  };

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

  age.secrets = {
    "authelia-hmac-secret" = {
      file = ../../../../secrets/authelia-hmac-secret.age;
      owner = user;
    };
    "authelia-jwt-private-key" = {
      file = ../../../../secrets/authelia-jwt-private-key.age;
      owner = user;
    };
    "authelia-jwt-secret" = {
      file = ../../../../secrets/authelia-jwt-secret.age;
      owner = user;
    };
    "authelia-ldap-password" = {
      file = ../../../../secrets/authelia-ldap-password.age;
      owner = user;
    };
    "authelia-session-secret" = {
      file = ../../../../secrets/authelia-session-secret.age;
      owner = user;
    };
    "authelia-smtp-password" = {
      file = ../../../../secrets/authelia-smtp-password.age;
      owner = user;
    };
    "authelia-storage-encryption-key" = {
      file = ../../../../secrets/authelia-storage-encryption-key.age;
      owner = user;
    };
  };
}
