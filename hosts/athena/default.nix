{ pkgs, ... }:

{
  imports = [
    ../common/global/darwin.nix
    ../common/users/matt
  ];

  networking.computerName = "Athena";
  networking.hostName = "athena";
}
