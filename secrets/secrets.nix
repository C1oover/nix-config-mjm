with import ./keys.nix;
{
  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "smb-creds.age".publicKeys = personalKeys ++ [ persephone ];

  "taskwarrior-key.age".publicKeys = personalKeys ++ [ leto ];
}
