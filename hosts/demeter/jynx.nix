{
  microvm.vms.jynx = {
    config = {
      mjm.loki.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:A4:7C:2E:BD:19";
        machineId = "4e9216abcf1f9c030be7749b68213b0e";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
