{
  microvm.vms.mrmime = {
    config = {
      mjm.home-assistant.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:DB:5B:0A:7B:71";
        machineId = "0dfb2a79d9ed217d66f2c0f56824baac";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };

  # make sure the VMM can access the device to pass it through to the VM
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", GROUP="kvm"
  '';
}
