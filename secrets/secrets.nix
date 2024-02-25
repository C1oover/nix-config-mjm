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

  "arges-approle-secret-id.age".publicKeys = personalKeys ++ [ arges ];
  "brontes-approle-secret-id.age".publicKeys = personalKeys ++ [ brontes ];
  "chaos-approle-secret-id.age".publicKeys = personalKeys ++ [ chaos ];
  "helios-approle-secret-id.age".publicKeys = personalKeys ++ [ helios ];
  "hypnos-approle-secret-id.age".publicKeys = personalKeys ++ [ hypnos ];
  "leto-approle-secret-id.age".publicKeys = personalKeys ++ [ leto ];
  "steropes-approle-secret-id.age".publicKeys = personalKeys ++ [ steropes ];

  "ngrok.age".publicKeys = [
    matt-athena
    athena
  ];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "restic-backup-env.age".publicKeys = personalKeys ++ allNixOS;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];
}
