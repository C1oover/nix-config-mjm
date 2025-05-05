{
  # microvm nixpkgs config won't have an effect, so we have to declare this here
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  microvm.vms.primeape = {
    config = {
      mjm.matrix-server.enable = true;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:1F:A0:AF:B6:BF";
        machineId = "c2b51d2c5d5e60ff06e7198968183deb";
      };

      microvm.mem = 1536;
      microvm.vcpu = 2;
      system.stateVersion = "25.05";
    };
  };
}
