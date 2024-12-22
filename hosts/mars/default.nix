{
  imports = [
    ../common/global/darwin
    ../common/users/mjm
  ];

  networking.computerName = "Mars";
  networking.hostName = "mars";

  ids.gids.nixbld = 30000;

  homebrew.enable = false;

  system.stateVersion = 5;
}
