{
  microvm.vms.voltorb = {
    config = {
      mjm.netbox.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:75:FD:1F:DB:87";
        machineId = "ca840fe606fdd2e77527efe9682a177f";
      };
      microvm.mem = 2048;
      system.stateVersion = "25.05";
    };
  };

  systemd.services."microvm@voltorb".serviceConfig.TimeoutStartSec = 600;
  systemd.services."microvm@voltorb".serviceConfig.TimeoutStopSec = 150;
}
