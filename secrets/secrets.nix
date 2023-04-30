let
  mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbkn+JHPdLiUO/M1U+ArBKSYm7BYqnC+G3q4S8L5EBK";

  matt-mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2L1UcEeHu537h8i3omMgYbGxf3/mp1yzZUat2jWY5n";

  megaera = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjL++8eZk0Ydrti+7EcyEvZp5AHCKz+R8IQ9ohs/KT7";
  tisiphone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqaFj8PGrEhie1P0uEKJ6lbP0fjB+CzuWw5siQGlsin";
  alecto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINq0z6ClXVPLPyucJEPg5EhqK//2JVexFGO4d9MT+cJY";
  hypnos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKn/ufUVxaDdTElgs61xfvsHsHn3RwpL7n6DO5qcBO0K";
in
{
  "nomad-token.age".publicKeys = [ mars ];

  "megaera-nomad-vault-config.age".publicKeys = [ matt-mars megaera ];
  "tisiphone-nomad-vault-config.age".publicKeys = [ matt-mars tisiphone ];
  "alecto-nomad-vault-config.age".publicKeys = [ matt-mars alecto ];

  "gitlab-runner-registration.age".publicKeys = [ matt-mars hypnos ];
}
