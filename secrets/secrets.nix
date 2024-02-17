let
  keys = import ./keys.nix;
in
with keys;
{
  "megaera-vault-unseal-env.age".publicKeys = personalKeys ++ [ megaera ];
  "tisiphone-vault-unseal-env.age".publicKeys = personalKeys ++ [ tisiphone ];
  "alecto-vault-unseal-env.age".publicKeys = personalKeys ++ [ alecto ];

  "gitlab-runner-registration.age".publicKeys = personalKeys ++ [
    hypnos
    arges
  ];

  "leto-approle-secret-id.age".publicKeys = personalKeys ++ [ leto ];
  "chaos-approle-secret-id.age".publicKeys = personalKeys ++ [ chaos ];
  "helios-approle-secret-id.age".publicKeys = personalKeys ++ [ helios ];

  "home-assistant-backup-password.age".publicKeys = personalKeys ++ [ leto ];
  "home-assistant-token.age".publicKeys = personalKeys ++ [ leto ];

  "ngrok.age".publicKeys = [
    matt-athena
    athena
  ];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;
  "restic-backup-env.age".publicKeys = personalKeys ++ allNixOS;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];
  "smb-creds-server.age".publicKeys = personalKeys ++ [ chaos ];
  "sabnzbd-apikey.age".publicKeys = personalKeys ++ [ chaos ];
  "sonarr-apikey.age".publicKeys = personalKeys ++ [ chaos ];
  "radarr-apikey.age".publicKeys = personalKeys ++ [ chaos ];
  "readarr-apikey.age".publicKeys = personalKeys ++ [ chaos ];

  "postgresql-backup-password.age".publicKeys = personalKeys ++ [
    themis
    leto
  ];

  "nut-primary-password.age".publicKeys = personalKeys ++ [ arges ];
  "nut-secondary-password.age".publicKeys = personalKeys ++ allNixOS;

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];

  "cloudflare-api-token.age".publicKeys = personalKeys ++ [
    brontes
    steropes
  ];
}
