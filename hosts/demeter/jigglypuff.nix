{ inputs, localModulesPath, ... }:
let
  machineId = "3828c078f418f0d05a2b511968127faf";
in
{
  # TODO do this automatically for all vms
  systemd.tmpfiles.settings."10-microvms" = {
    "/var/log/journal/${machineId}"."L+".argument = "/var/lib/microvms/jigglypuff/journal/${machineId}";
  };

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
          inherit machineId;
        };
        system.stateVersion = "25.05";
      };
    };
  };
}
