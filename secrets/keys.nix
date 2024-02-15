rec {
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
  chaos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO304X73466BZXsreuqu+9IWjIZExH6uw55Qia1+Nmhc";
  leto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJozGY8MtncB4AF+0k7l6jSxWJwQgLl5/YCpeXgCtKDH";
  rhea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaVCGokUWFMh7D+bqSY0vd5YrTMKdFmkEHJfqOVHRM6";
  cronus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUriBaPvCj6y41zPhsxilpHG59b5ueVfx2eXwIcvZX";
  themis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+W3nQy3t3HePyqVHTL5W0zOl5fgDQYvIt6TuxPA51g";
  nyx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2pPaX+7EoXMTzgmfoBJ7AeiXwfqq/LqKdbj8kcOa1P";
  persephone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNcGvd0FkGDH7rm02jm8fan2xqKoEr/Wx+3wAgfDR7A";
  matt-persephone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/65Yq1UkZie8WgsO2HUGq9bq++Y6o+FJd8wWvWhdLx";
  matt-uranus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsOTXJIL5BfbiVcvrHLf49u+o6ja6DMJxzjmeJ7tPKu";

  servers = {
    inherit
      megaera
      tisiphone
      alecto
      arges
      brontes
      steropes
      hypnos
      helios
      chaos
      leto
      rhea
      cronus
      themis
      nyx
      ;
  };

  nomadClients = [
    arges
    brontes
    steropes
    helios
  ];
  allNixOS = [ persephone ] ++ (builtins.attrValues servers);
  personalKeys = [
    matt-athena
    matt-mars
    matt-persephone
    matt-uranus
  ];
}
