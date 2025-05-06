{
  microvm.vms.bulbasaur = {
    config = {
      mjm.consul.server.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:7E:1D:15:9E:3B";
        machineId = "8f7c05f6322c7f1a4c3e57b968197146";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
