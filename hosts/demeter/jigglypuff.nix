{ inputs, localModulesPath, ... }:
{
  microvm.vms.jigglypuff = {
    # TODO make this automatic
    autostart = true;
    specialArgs = {
      inherit inputs localModulesPath;
      nodes = { };
    };

    config = {
      imports = [ "${localModulesPath}/nixos" ];

      config = {
        mjm.navidrome.enable = true;

        mjm.profiles.microvm = {
          enable = true;
          # TODO get this from the host
          hostPool = "fast";
          macAddress = "02:59:AB:9A:5A:43";
          machineId = "3828c078f418f0d05a2b511968127faf";
        };
        system.stateVersion = "25.05";
      };
    };
  };
}
