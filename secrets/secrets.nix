with import ./keys.nix;
let
  hashistack = [
    megaera
    tisiphone
    alecto
  ];
in
{
  "megaera-vault-unseal-env.age".publicKeys = personalKeys ++ [ megaera ];
  "tisiphone-vault-unseal-env.age".publicKeys = personalKeys ++ [ tisiphone ];
  "alecto-vault-unseal-env.age".publicKeys = personalKeys ++ [ alecto ];

  "vault-backup-secret-id.age".publicKeys = personalKeys ++ hashistack;
  "vault-backup-password.age".publicKeys = personalKeys ++ hashistack;

  "gitlab-runner-registration.age".publicKeys = personalKeys ++ [
    hypnos
    arges
  ];

  "leto-approle-secret-id.age".publicKeys = personalKeys ++ [ leto ];
  "chaos-approle-secret-id.age".publicKeys = personalKeys ++ [ chaos ];
  "helios-approle-secret-id.age".publicKeys = personalKeys ++ [ helios ];

  "ngrok.age".publicKeys = [
    matt-athena
    athena
  ];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;
  "restic-backup-env.age".publicKeys = personalKeys ++ allNixOS;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];

  "nut-primary-password.age".publicKeys = personalKeys ++ [ arges ];
  "nut-secondary-password.age".publicKeys = personalKeys ++ allNixOS;

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];

  "cloudflare-api-token.age".publicKeys = personalKeys ++ [
    brontes
    steropes
  ];
}
