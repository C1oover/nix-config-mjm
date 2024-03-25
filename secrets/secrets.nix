with import ./keys.nix;
let
  hashistack = [
    megaera
    tisiphone
    alecto
  ];
in
{
  "vault-backup-secret-id.age".publicKeys = personalKeys ++ hashistack;
  "vault-backup-password.age".publicKeys = personalKeys ++ hashistack;
  "restic-backup-env.age".publicKeys = personalKeys ++ hashistack;
  "restic-backup-offsite-env.age".publicKeys = personalKeys ++ hashistack;

  "ngrok.age".publicKeys = [
    matt-athena
    athena
  ];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];
}
