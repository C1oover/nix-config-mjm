{
  microvm.vms.abra = {
    config = {
      mjm.grafana.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:CF:C9:87:EA:4B";
        machineId = "79de4721f4356e5584b33be1682361ba";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
