{
  microvm.vms.drowzee = {
    config = {
      mjm.alertmanager.enable = true;

      mjm.spire.agent.joinToken = "c5d4d507-2a2e-4550-b020-af296fd320e4";

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:B8:B4:DB:FD:1F";
        machineId = "d65b1d3551f0e07a6fbc33826820cf94";
      };
      system.stateVersion = "25.05";
    };
  };
}
