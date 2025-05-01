{ lib, config, ... }:
let
  inherit (lib) mapAttrs' mkEnableOption mkIf;
  cfg = config.mjm.microvm-host;
in
{
  options.mjm.microvm-host = {
    enable = mkEnableOption "MicroVM host";
  };

  config = mkIf cfg.enable {
    systemd.network.networks."10-microvm" = {
      name = "vm-*";
      networkConfig.Bridge = mkIf config.mjm.networkd.bridge.enable "vmbr0";
    };

    microvm.host.enable = true;

    systemd.tmpfiles.settings."10-microvms" = mapAttrs' (
      name: vm:
      let
        machineId = vm.config.config.mjm.profiles.microvm.machineId;
      in
      {
        name = "/var/log/journal/${machineId}";
        value."L+".argument = "/var/lib/microvms/${name}/journal/${machineId}";
      }
    ) config.microvm.vms;
  };
}
