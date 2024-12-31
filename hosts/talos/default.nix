{
  imports = [ ../common/users/matt ];

  mjm.username = "mjm";

  networking.computerName = "Talos";
  networking.hostName = "talos";

  homebrew.enable = false;

  mjm.consul.enable = true;
  mjm.matrix-server.bridges.imessage.enable = true;
  mjm.server.enable = true;

  system.stateVersion = 5;
  nixpkgs.system = "x86_64-darwin";
}
