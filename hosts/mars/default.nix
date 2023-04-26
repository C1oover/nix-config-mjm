{ pkgs, ... }:

{
  imports = [
    ../common/global/darwin.nix
    ../common/users/matt
  ];

  networking.computerName = "Mars";
  networking.hostName = "mars";

  age.secrets.nomad-token = {
    file = secrets/nomad-token.age;
    owner = "matt";
  };
}
