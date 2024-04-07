with import ./keys.nix;
{
  "newsboat-miniflux-token.age".publicKeys = personalKeys;
  "taskwarrior-key.age".publicKeys = personalKeys;
}
