{
  imports = [ ../common/users/matt ];

  mjm.username = "mjm";

  networking.computerName = "Mars";
  networking.hostName = "mars";

  ids.gids.nixbld = 30000;

  homebrew.enable = false;

  mjm.matrix-server.bridges.imessage.enable = true;

  system.stateVersion = 5;
  nixpkgs.system = "x86_64-darwin";
}
