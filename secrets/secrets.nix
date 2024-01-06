let
  keys = import ./keys.nix;
in
  with keys; {
    "megaera-nomad-vault-config.age".publicKeys = personalKeys ++ [megaera];
    "tisiphone-nomad-vault-config.age".publicKeys = personalKeys ++ [tisiphone];
    "alecto-nomad-vault-config.age".publicKeys = personalKeys ++ [alecto];

    "nomad-docker-auth.age".publicKeys = personalKeys ++ nomadClients;

    "gitlab-runner-registration.age".publicKeys = personalKeys ++ [hypnos arges];

    "lldap-approle-secret-id.age".publicKeys = personalKeys ++ [leto];

    "authelia-jwt-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-jwt-private-key.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-storage-encryption-key.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-session-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-hmac-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-smtp-password.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-ldap-password.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-approle-secret-id.age".publicKeys = personalKeys ++ [orion leto];

    "netbox-secret-key.age".publicKeys = personalKeys ++ [nemesis leto];
    "netbox-approle-secret-id.age".publicKeys = personalKeys ++ [nemesis leto];
    "attic-approle-secret-id.age".publicKeys = personalKeys ++ [nemesis leto];

    "paperless-approle-secret-id.age".publicKeys = personalKeys ++ [aion leto];

    "alertmanager-env.age".publicKeys = personalKeys ++ [gaia];

    "ngrok.age".publicKeys = [matt-athena athena];

    "newsboat-miniflux-token.age".publicKeys = personalKeys;

    "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;

    "smb-creds.age".publicKeys = personalKeys ++ [persephone];
    "smb-creds-server.age".publicKeys = personalKeys ++ [chaos];
    "sabnzbd-apikey.age".publicKeys = personalKeys ++ [chaos];

    "nut-primary-password.age".publicKeys = personalKeys ++ [arges];
    "nut-secondary-password.age".publicKeys = personalKeys ++ allNixOS;

    "taskwarrior-key.age".publicKeys = personalKeys;

    "cloudflare-api-token.age".publicKeys = personalKeys ++ [brontes steropes];

    "minio-root-credentials.age".publicKeys = personalKeys ++ [phoebe];
  }
