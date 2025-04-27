{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.mjm.profiles.microvm;
in
{
  imports = [ "${inputs.microvm}/nixos-modules/microvm/options.nix" ];

  options.mjm.profiles.microvm = {
    enable = mkEnableOption "MicroVM profile";
    hostPool = mkOption {
      type = types.str;
    };
    macAddress = mkOption {
      type = types.str;
    };
    machineId = mkOption {
      type = types.str;
    };
  };

  config = mkMerge [
    { microvm.guest.enable = mkDefault false; }
    (mkIf cfg.enable {
      microvm = {
        guest.enable = true;
        hypervisor = "cloud-hypervisor";
        interfaces = [
          {
            type = "tap";
            id = "vm-${config.networking.hostName}";
            mac = cfg.macAddress;
          }
        ];
        shares =
          [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              proto = "virtiofs";
            }
          ]
          ++ map (d: rec {
            proto = "virtiofs";
            # TODO maybe make this an option, if needed to disambiguate
            tag = builtins.baseNameOf d.directory;
            source = tag;
            mountPoint = d.directory;
          }) config.mjm.state.directories;
        # This doesn't work as expected, they need to be set up earlier
        # preStart = concatMapStringsSep "\n" (d: ''
        #   zfs create -p ${cfg.hostPool}/microvms/${config.networking.hostName}/${builtins.baseNameOf d.directory};
        # '') config.mjm.state.directories;
      };

      environment.etc."machine-id".text = cfg.machineId;

      mjm.username = "mjm";
      mjm.minimal.enable = true;

      mjm.consul.enable = true;
      mjm.server.enable = true;
      mjm.spire.agent.enable = true;
    })
  ];
}
