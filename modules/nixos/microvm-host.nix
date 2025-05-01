{
  lib,
  config,
  inputs,
  localModulesPath,
  ...
}:
let
  inherit (lib)
    concatMapAttrs
    concatMapStringsSep
    hasPrefix
    mapAttrs'
    mkBefore
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  cfg = config.mjm.microvm-host;
in
{
  options.mjm.microvm-host = {
    enable = mkEnableOption "MicroVM host";
    zfsPrefix = mkOption {
      type = types.str;
    };
  };

  options.microvm.vms = mkOption {
    type = types.attrsOf (
      types.submodule {
        config = {
          autostart = mkDefault true;
          specialArgs = {
            inherit inputs localModulesPath;
            # TODO decide how to do this properly
            nodes = { };
          };

          config = {
            imports = [ "${localModulesPath}/nixos" ];
          };
        };
      }
    );
  };

  config = mkIf cfg.enable {
    systemd.network.networks."10-microvm" = mkIf config.mjm.networkd.bridge.enable {
      name = "vm-*";
      networkConfig.Bridge = "vmbr0";
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

    systemd.services = concatMapAttrs (name: vm: {
      "install-microvm-${name}" = {
        path = [ config.boot.zfs.package ];
        script = mkBefore (
          concatMapStringsSep "\n" (
            share:
            optionalString (!(hasPrefix "/" share.source)) ''
              zfs create -p ${cfg.zfsPrefix}/microvms/${name}/${share.source}
            ''
          ) vm.config.config.microvm.shares
        );
      };
    }) config.microvm.vms;
  };
}
