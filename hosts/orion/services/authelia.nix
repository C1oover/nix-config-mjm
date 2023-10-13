{
  config,
  pkgs,
  ...
}: let
  oidcClients = [
    {
      id = "gitlab";
      description = "GitLab";
      secret = "$pbkdf2-sha512$310000$KBrmIfaP43sBTkOZ5tvwlA$y8/qNNGAeeco48h4vsmtqA73thgVubddQOepMfqG3w0zEvnWPf9w/L8kJpuanGwKtwkejAC.g.M4sQ.Q1qY6OQ";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://git.midna.dev/users/auth/openid_connect/callback"
      ];
      scopes = ["openid" "profile" "groups" "email"];
      userinfo_signing_algorithm = "none";
    }
    {
      id = "vault";
      description = "Hashicorp Vault";
      secret = "$pbkdf2-sha512$310000$GcSGTc2f7qUrSu9cM1cGvQ$IJ.jX/HZx3lVujQbbdCp66vm2qWX8M6MEK1peMeTI1GZxMWaVRlVC59tGkIW08ij6WliBEfTvSTSToKmXYEGTQ";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://vault.home.mattmoriarity.com/oidc/callback"
        "https://vault.home.mattmoriarity.com/ui/vault/auth/oidc/oidc/callback"
        "http://localhost:8250/oidc/callback"
      ];
      scopes = ["openid" "profile" "groups" "email"];
      userinfo_signing_algorithm = "none";
    }
    {
      id = "proxmox";
      description = "Proxmox Virtual Environment";
      secret = "$pbkdf2-sha512$310000$jSR5KT8pbsKrYovaP0RYhA$pt40j9SHmF3SfZPgxGfmQZKfS.07Zks7MkmCHuAzJaEOY0Gca1CzvFwczMWhFHiRTd1tOsLzKY1yGAdYb1Q9sA";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://10.0.2.10:8006"
        "https://10.0.2.11:8006"
        "https://artemis.home.mattmoriarity.com:8006"
        "https://apollo.home.mattmoriarity.com:8006"
        "https://proxmox.home.mattmoriarity.com"
      ];
      scopes = ["openid" "profile" "email"];
      userinfo_signing_algorithm = "none";
    }
    {
      id = "minio";
      description = "MinIO";
      secret = "$pbkdf2-sha512$310000$lIbZcunKd9pcd.e/8.8esw$lJY3Zb7Ng8eSKHXV3xI9BA2THWMy7ZcCPYX/pCjuLw32nxN4stMnnIXb8poFbX8DFxvrWHT5sPeRWFl532RxHg";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = ["https://minio-console.home.mattmoriarity.com/oauth_callback"];
      scopes = ["openid" "profile" "groups" "email"];
      userinfo_signing_algorithm = "none";
    }
  ];

  inherit (config.services.authelia.instances.main) user group;
in {
  services.authelia.instances.main = {
    enable = true;
    settings = {
      default_redirection_url = "https://homelab.home.mattmoriarity.com/";
      default_2fa_method = "webauthn";
      server.host = "0.0.0.0";
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
        rules = [
          {
            domain = "*.home.mattmoriarity.com";
            networks = ["10.0.2.104"];
            policy = "bypass";
          }
        ];
      };
      session.domain = "home.mattmoriarity.com";
      session.redis = {
        host = "redis.service.consul";
        port = 6379;
      };
      storage.postgres = {
        host = "postgresql.service.consul";
        port = 5432;
        database = "authelia";
      };
      notifier.smtp = {
        host = "smtp.fastmail.com";
        port = 587;
        username = "matt@mattmoriarity.com";
        sender = "Authelia <admin@mattmoriarity.com>";
      };
      identity_providers.oidc.clients = oidcClients;
    };
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-jwt-secret".path;
      oidcHmacSecretFile = config.age.secrets."authelia-hmac-secret".path;
      oidcIssuerPrivateKeyFile = config.age.secrets."authelia-jwt-private-key".path;
      sessionSecretFile = config.age.secrets."authelia-session-secret".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-storage-encryption-key".path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets."authelia-ldap-password".path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."authelia-smtp-password".path;
    };
    settingsFiles = [
      "/run/secrets/authelia/db-config.yml"
    ];
  };

  services.authelia.instances.external = {
    inherit user group;
    enable = true;
    settings = {
      default_redirection_url = "https://git.midna.dev/";
      default_2fa_method = "webauthn";
      server.host = "0.0.0.0";
      server.port = 9092;
      telemetry.metrics = {
        enabled = true;
        address = "tcp://0.0.0.0:9960";
      };
      webauthn.display_name = "Homelab External";
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
        rules = [
          {
            domain = "links.midna.dev";
            resources = ["^/api/.*$"];
            policy = "bypass";
          }
          {
            domain = "feeds.midna.dev";
            resources = [
              "^/v1/.*$"
              "^/accounts/ClientLogin$"
              "^/reader/api/0/.*$"
            ];
            policy = "bypass";
          }
        ];
      };
      session.domain = "midna.dev";
      session.redis = {
        host = "redis.service.consul";
        port = 6379;
        database_index = 3;
      };
      storage.postgres = {
        host = "postgresql.service.consul";
        port = 5432;
        database = "authelia_external";
      };
      notifier.smtp = {
        host = "smtp.fastmail.com";
        port = 587;
        username = "matt@mattmoriarity.com";
        sender = "Authelia <admin@mattmoriarity.com>";
      };
      identity_providers.oidc.clients = oidcClients;
    };
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-jwt-secret".path;
      oidcHmacSecretFile = config.age.secrets."authelia-hmac-secret".path;
      oidcIssuerPrivateKeyFile = config.age.secrets."authelia-jwt-private-key".path;
      sessionSecretFile = config.age.secrets."authelia-session-secret".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-storage-encryption-key".path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets."authelia-ldap-password".path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."authelia-smtp-password".path;
    };
    settingsFiles = [
      "/run/secrets/authelia/db-config.yml"
    ];
  };

  systemd.services.authelia-main.after = ["lldap.service"];
  systemd.services.authelia-external.after = ["lldap.service"];

  networking.firewall.allowedTCPPorts = [
    9091
    9092
    9959
    9960
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

  services.consul.services.authelia-external = {
    port = 9092;

    meta = {
      metrics_path = "/metrics";
      metrics_port = "9960";
    };

    checks = [
      {
        name = "authelia is ready";
        http = "http://localhost:9092/api/health";
        interval = "30s";
        timeout = "5s";
      }
    ];
  };

  systemd.tmpfiles.rules = ["d /run/secrets/authelia 0700 ${user} ${group} - -"];

  services.vault-agent.instances.authelia.settings = let
    va = import ../../../lib/vault-agent.nix {inherit pkgs;};
  in
    va.mkConfig {
      roleId = "1f94fc98-0934-7027-a34f-ea94f3268def";
      secretIdFile = config.age.secrets."authelia-approle-secret-id".path;
      templates = [
        {
          contents = ''
            {{ with secret "database/creds/authelia" }}
            storage:
              postgres:
                username: {{ .Data.username | toJSON }}
                password: {{ .Data.password | toJSON }}
            {{ end }}
          '';
          destination = "/run/secrets/authelia/db-config.yml";
          command = "systemctl restart authelia-main.service authelia-external.service";
        }
      ];
    };

  age.secrets = {
    "authelia-hmac-secret" = {
      file = ../../../secrets/authelia-hmac-secret.age;
      owner = user;
    };
    "authelia-jwt-private-key" = {
      file = ../../../secrets/authelia-jwt-private-key.age;
      owner = user;
    };
    "authelia-jwt-secret" = {
      file = ../../../secrets/authelia-jwt-secret.age;
      owner = user;
    };
    "authelia-ldap-password" = {
      file = ../../../secrets/authelia-ldap-password.age;
      owner = user;
    };
    "authelia-session-secret" = {
      file = ../../../secrets/authelia-session-secret.age;
      owner = user;
    };
    "authelia-smtp-password" = {
      file = ../../../secrets/authelia-smtp-password.age;
      owner = user;
    };
    "authelia-storage-encryption-key" = {
      file = ../../../secrets/authelia-storage-encryption-key.age;
      owner = user;
    };
    "authelia-approle-secret-id" = {
      file = ../../../secrets/authelia-approle-secret-id.age;
      owner = user;
    };
  };
}
