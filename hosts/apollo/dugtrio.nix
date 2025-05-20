{ lib, ... }:
{
  microvm.vms.dugtrio = {
    # rebooting gitlab during a deploy can cause it to fail
    restartIfChanged = false;

    config = {
      mjm.gitlab.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        useHostStore = false;
        macAddress = "02:CB:78:AD:51:4A";
        machineId = "91a269b24ff06ee998280e8e68159f6f";
      };

      # yikes, gitlab needs a lot of ram
      microvm.mem = 8192;
      microvm.vcpu = 4;
      microvm.storeDiskType = "squashfs";
      microvm.hypervisor = lib.mkForce "qemu";
      system.stateVersion = "25.05";
    };
  };
}
