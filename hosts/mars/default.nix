{
  imports = [
    ../common/global/darwin
    ../common/users/mjm

    ../../services/matrix-server/mautrix-imessage.nix
  ];

  networking.computerName = "Mars";
  networking.hostName = "mars";

  ids.gids.nixbld = 30000;

  homebrew.enable = false;

  mjm.matrix-server.bridges.imessage.enable = true;

  system.stateVersion = 5;
}
