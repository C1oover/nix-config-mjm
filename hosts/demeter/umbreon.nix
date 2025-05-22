{
  microvm.vms.umbreon = {
    config = {
      mjm.readarr = {
        enable = true;
        suffix = "-audio";
        mediaDir = "/videos/audiobooks";
        subdomain = "audiobooks";
      };

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:EF:09:B4:BA:CC";
        machineId = "64b3030d1ea9bed2e5369d97682eb381";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
