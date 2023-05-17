let
  mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbkn+JHPdLiUO/M1U+ArBKSYm7BYqnC+G3q4S8L5EBK";

  matt-mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2L1UcEeHu537h8i3omMgYbGxf3/mp1yzZUat2jWY5n";

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

  nomadClients = [arges brontes steropes helios];
in {
  "megaera-nomad-vault-config.age".publicKeys = [matt-mars megaera];
  "tisiphone-nomad-vault-config.age".publicKeys = [matt-mars tisiphone];
  "alecto-nomad-vault-config.age".publicKeys = [matt-mars alecto];

  "nomad-docker-auth.age".publicKeys = [matt-mars] ++ nomadClients;

  "gitlab-runner-registration.age".publicKeys = [matt-mars hypnos];

  "authelia-jwt-secret.age".publicKeys = [matt-mars orion];
  "authelia-jwt-private-key.age".publicKeys = [matt-mars orion];
  "authelia-storage-encryption-key.age".publicKeys = [matt-mars orion];
  "authelia-session-secret.age".publicKeys = [matt-mars orion];
  "authelia-hmac-secret.age".publicKeys = [matt-mars orion];
  "authelia-smtp-password.age".publicKeys = [matt-mars orion];
  "authelia-ldap-password.age".publicKeys = [matt-mars orion];
  "authelia-approle-secret-id.age".publicKeys = [matt-mars orion];

  "netbox-secret-key.age".publicKeys = [matt-mars nemesis];
  "netbox-approle-secret-id.age".publicKeys = [matt-mars nemesis];

  "paperless-approle-secret-id.age".publicKeys = [matt-mars aion];

  "alertmanager-env.age".publicKeys = [matt-mars gaia];
}
