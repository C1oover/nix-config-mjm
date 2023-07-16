let
  # mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbkn+JHPdLiUO/M1U+ArBKSYm7BYqnC+G3q4S8L5EBK";
  athena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRdADDECsuvTNVQAODyHrQ8HoKXa4Q1S9yBkcybnUCR";
  matt-mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2L1UcEeHu537h8i3omMgYbGxf3/mp1yzZUat2jWY5n";
  matt-athena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi3SELPy05ZcWXQw0DH9IiOtuBXDnhy/cx2LSgj09CZ";

  megaera = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjL++8eZk0Ydrti+7EcyEvZp5AHCKz+R8IQ9ohs/KT7";
  tisiphone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqaFj8PGrEhie1P0uEKJ6lbP0fjB+CzuWw5siQGlsin";
  alecto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINq0z6ClXVPLPyucJEPg5EhqK//2JVexFGO4d9MT+cJY";
  arges = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS3pPNEaHA+ycDa7kTyNSxsAYBFZI7YMweDrrN0Gg+l";
  brontes = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK3Cibu7YdRQeQcTWKOB59ExP+UsaJbW5F+lrvEbBUJ";
  steropes = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjKfsGgQgS1q/t73Y/kFh9fPZwlPH2iyZDqW2rKC2uL";
  hypnos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKn/ufUVxaDdTElgs61xfvsHsHn3RwpL7n6DO5qcBO0K";
  helios = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUqz5VSSneEjQXfTrFiK8dfbclhClA9faM1gobRaqJy";
  orion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFDLe0Oy6quuAu4ARXnZCWNDiYTgfdLjy7kp7MB8n4G";
  nemesis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOBXAwxTy5mDt9jxKg1rhRryyNr5jkIPHnwAdLsQ1yI";
  aion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFrAsGVNyUfMfNvdix1ON28I/eu4MBhU6YdzzgRItQf";
  gaia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKBvQP0w1opkY5E8xZzVZodNDd/2HWdHYvjulULaK6t";
  phoebe = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3F9IyWUYEHVqhq4gc1wtyvOqgNTZsF+LJjhknuvG3E";
  themis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+W3nQy3t3HePyqVHTL5W0zOl5fgDQYvIt6TuxPA51g";
  persephone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNcGvd0FkGDH7rm02jm8fan2xqKoEr/Wx+3wAgfDR7A";
  matt-persephone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/65Yq1UkZie8WgsO2HUGq9bq++Y6o+FJd8wWvWhdLx";

  nomadClients = [arges brontes steropes helios];
  allNixOS = [
    megaera
    tisiphone
    alecto
    arges
    brontes
    steropes
    hypnos
    helios
    orion
    nemesis
    aion
    gaia
    phoebe
    themis
    persephone
  ];
  personalKeys = [matt-mars matt-persephone];
in {
  "megaera-nomad-vault-config.age".publicKeys = personalKeys ++ [megaera];
  "tisiphone-nomad-vault-config.age".publicKeys = personalKeys ++ [tisiphone];
  "alecto-nomad-vault-config.age".publicKeys = personalKeys ++ [alecto];

  "nomad-docker-auth.age".publicKeys = personalKeys ++ nomadClients;

  "gitlab-runner-registration.age".publicKeys = personalKeys ++ [hypnos];

  "authelia-jwt-secret.age".publicKeys = personalKeys ++ [orion];
  "authelia-jwt-private-key.age".publicKeys = personalKeys ++ [orion];
  "authelia-storage-encryption-key.age".publicKeys = personalKeys ++ [orion];
  "authelia-session-secret.age".publicKeys = personalKeys ++ [orion];
  "authelia-hmac-secret.age".publicKeys = personalKeys ++ [orion];
  "authelia-smtp-password.age".publicKeys = personalKeys ++ [orion];
  "authelia-ldap-password.age".publicKeys = personalKeys ++ [orion];
  "authelia-approle-secret-id.age".publicKeys = personalKeys ++ [orion];

  "netbox-secret-key.age".publicKeys = personalKeys ++ [nemesis];
  "netbox-approle-secret-id.age".publicKeys = personalKeys ++ [nemesis];

  "paperless-approle-secret-id.age".publicKeys = personalKeys ++ [aion];

  "alertmanager-env.age".publicKeys = personalKeys ++ [gaia];

  "ngrok.age".publicKeys = [matt-athena athena];

  "newsboat-miniflux-token.age".publicKeys = personalKeys;

  "nixremote-key.age".publicKeys = personalKeys ++ allNixOS;

  "wpa-supplicant-env.age".publicKeys = personalKeys ++ [persephone];
}
