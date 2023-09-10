let
  keys = import ./keys.nix;
in
  with keys; {
    "megaera-nomad-vault-config.age".publicKeys = personalKeys ++ [megaera];
    "tisiphone-nomad-vault-config.age".publicKeys = personalKeys ++ [tisiphone];
    "alecto-nomad-vault-config.age".publicKeys = personalKeys ++ [alecto];

    "nomad-docker-auth.age".publicKeys = personalKeys ++ nomadClients;

    "gitlab-runner-registration.age".publicKeys = personalKeys ++ [hypnos arges];

    "authelia-jwt-secret.age".publicKeys = personalKeys ++ [orion];
    "authelia-jwt-private-key.age".publicKeys = personalKeys ++ [orion];
    "authelia-storage-encryption-key.age".publicKeys = personalKeys ++ [orion];
    "authelia-session-secret.age".publicKeys = personalKeys ++ [orion];
    "authelia-hmac-secret.age".publicKeys = personalKeys ++ [orion];
    "authelia-smtp-password.age".publicKeys = personalKeys ++ [orion];
    "authelia-ldap-password.age".publicKeys = personalKeys ++ [orion];
    "authelia-approle-secret-id.age".publicKeys = personalKeys ++ [orion];

    "netbox-secret-key.age".publicKeys = personalKeys ++ [nemesis];
    "netbox-approle-secret-id.age".publicKeys = personalKeys ++ [nemesis];

    "paperless-approle-secret-id.age".publicKeys = personalKeys ++ [aion];

    "alertmanager-env.age".publicKeys = personalKeys ++ [gaia];

    # "ngrok.age".publicKeys = [matt-athena athena];

    "newsboat-miniflux-token.age".publicKeys = personalKeys;

    "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;

    "wpa-supplicant-env.age".publicKeys = personalKeys ++ [persephone];

    "nut-server-upsmon-conf.age".publicKeys = personalKeys ++ [arges];
    "nut-server-upsd-users.age".publicKeys = personalKeys ++ [arges];
    "nut-client-upsmon-conf.age".publicKeys = personalKeys ++ allNixOS;
  }
