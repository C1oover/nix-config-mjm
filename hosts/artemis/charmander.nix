{
  microvm.vms.charmander = {
    config = {
      mjm.consul.server.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:BD:D1:E0:03:A6";
        machineId = "6a29b5aa6c05fb7f1ac325816820a93b";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
