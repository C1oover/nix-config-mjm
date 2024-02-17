{ config, ... }:
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
    secrets.manual = true;
    environmentVariables = {
      AUTHELIA_JWT_SECRET_FILE = "%d/jwt-secret";
      AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "%d/hmac-secret";
      AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = "%d/jwt-private-key";
      AUTHELIA_SESSION_SECRET_FILE = "%d/session-secret";
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/storage-encryption-key";
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap-password";
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "%d/smtp-password";
    };
  };

  vault-secrets.templates = {
    authelia-jwt-secret.kvPath = "kv/authelia/jwt_secret";
    authelia-hmac-secret.kvPath = "kv/authelia/hmac_secret";
    authelia-jwt-private-key.kvPath = "kv/authelia/jwt_private_key";
    authelia-session-secret.kvPath = "kv/authelia/session_secret";
    authelia-storage-encryption-key.kvPath = "kv/authelia/storage_encryption_key";
    authelia-ldap-password.kvPath = "kv/authelia/ldap_password";
    authelia-smtp-password.kvPath = "kv/authelia/fastmail_password";
  };

  systemd.services.authelia-main = {
    after = [
      "lldap.service"
      "redis-authelia.service"
      "postgresql.service"
      "render-vault-secrets.service"
    ];
    serviceConfig = {
      SupplementaryGroups = [ config.services.redis.servers.authelia.user ];
      LoadCredential =
        map (name: "${name}:${config.vault-secrets.templates.${"authelia-" + name}.path}")
          [
            "jwt-secret"
            "hmac-secret"
            "jwt-private-key"
            "ldap-password"
            "session-secret"
            "smtp-password"
            "storage-encryption-key"
          ];
    };
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
}
