let
  mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbkn+JHPdLiUO/M1U+ArBKSYm7BYqnC+G3q4S8L5EBK";
in
{
  "nomad-token.age".publicKeys = [ mars ];
}
