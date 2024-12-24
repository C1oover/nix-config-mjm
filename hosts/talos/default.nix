{
  imports = [
    ../common/global/darwin
    ../common/users/mjm

    ../../services/matrix-server/mautrix-imessage.nix
  ];

  networking.computerName = "Talos";
  networking.hostName = "talos";

  homebrew.enable = false;

  mjm.matrix-server.bridges.imessage.enable = true;

  system.stateVersion = 5;
}
