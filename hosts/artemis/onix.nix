{ pkgs, ... }:
{
  microvm.vms.onix = {
    config = {
      mjm.authelia.enable = true;

      services.postgresql.package = pkgs.postgresql_17;

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:C8:2B:22:DD:6A";
        machineId = "5e2ad33667082af442243802681c0c9f";
      };
      microvm.mem = 768;
      system.stateVersion = "25.05";
    };
  };
}
