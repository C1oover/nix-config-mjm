{
  mjm.homelab.enableYubiKey = true;

  programs.ssh = {
    addKeysToAgent = "yes";
    controlMaster = "auto";
    controlPersist = "5m";
  };
}
