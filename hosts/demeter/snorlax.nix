{
  microvm.vms.snorlax = {
    config = {
      mjm.jellyfin.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:FA:BD:AD:41:EF";
        machineId = "33e7682a6196ddc0e17fcbc468157527";
      };
      microvm.mem = 1536;
      system.stateVersion = "25.05";
    };
  };
}
