{
  mjm.username = "mjm";

  networking.computerName = "Talos";
  networking.hostName = "talos";

  homebrew.enable = false;

  mjm.consul.enable = true;
  mjm.matrix-server.bridges.imessage.enable = true;
  mjm.server.enable = true;
  mjm.spire.agent.enable = true;

  system.stateVersion = 5;
  nixpkgs.system = "x86_64-darwin";
}
