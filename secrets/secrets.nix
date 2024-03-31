with import ./keys.nix;
{
  "ngrok.age".publicKeys = [
    matt-athena
    athena
  ];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];
}
