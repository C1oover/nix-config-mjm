let
  keys = import ./keys.nix;
in
  with keys; {
    "megaera-nomad-vault-config.age".publicKeys = personalKeys ++ [megaera];
    "tisiphone-nomad-vault-config.age".publicKeys = personalKeys ++ [tisiphone];
    "alecto-nomad-vault-config.age".publicKeys = personalKeys ++ [alecto];

    "nomad-docker-auth.age".publicKeys = personalKeys ++ nomadClients;

    "gitlab-runner-registration.age".publicKeys = personalKeys ++ [hypnos arges];

    "leto-approle-secret-id.age".publicKeys = personalKeys ++ [leto];
    "authelia-jwt-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-jwt-private-key.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-storage-encryption-key.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-session-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-hmac-secret.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-smtp-password.age".publicKeys = personalKeys ++ [orion leto];
    "authelia-ldap-password.age".publicKeys = personalKeys ++ [orion leto];
    "netbox-secret-key.age".publicKeys = personalKeys ++ [nemesis leto];
    "alertmanager-env.age".publicKeys = personalKeys ++ [gaia leto];
    "pve-exporter-config.age".publicKeys = personalKeys ++ [leto];
    "vaultwarden-backup-password.age".publicKeys = personalKeys ++ [leto];
    "home-assistant-backup-password.age".publicKeys = personalKeys ++ [leto];
    "home-assistant-token.age".publicKeys = personalKeys ++ [leto];
    "paperless-backup-password.age".publicKeys = personalKeys ++ [leto];

    "garage-env.age".publicKeys = personalKeys ++ [leto chaos helios];

    "ngrok.age".publicKeys = [matt-athena athena];

    "newsboat-miniflux-token.age".publicKeys = personalKeys;

    "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;
    "restic-backup-env.age".publicKeys = personalKeys ++ allNixOS;

    "smb-creds.age".publicKeys = personalKeys ++ [persephone];
    "smb-creds-server.age".publicKeys = personalKeys ++ [chaos];
    "sabnzbd-apikey.age".publicKeys = personalKeys ++ [chaos];
    "sonarr-apikey.age".publicKeys = personalKeys ++ [chaos];
    "radarr-apikey.age".publicKeys = personalKeys ++ [chaos];
    "readarr-apikey.age".publicKeys = personalKeys ++ [chaos];

    "postgresql-backup-password.age".publicKeys = personalKeys ++ [themis];

    "nut-primary-password.age".publicKeys = personalKeys ++ [arges];
    "nut-secondary-password.age".publicKeys = personalKeys ++ allNixOS;

    "taskwarrior-key.age".publicKeys = personalKeys;

    "cloudflare-api-token.age".publicKeys = personalKeys ++ [brontes steropes];

    "minio-root-credentials.age".publicKeys = personalKeys ++ [phoebe];
  }
