{
  microvm.vms.squirtle = {
    config = {
      mjm.consul.server.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:ED:BD:42:DF:42";
        machineId = "1b373e7186662dd67cf7dbd76814edfd";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
