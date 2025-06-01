{
  lib,
  config,
  hostConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.cloover.profiles.microvm;

  microvm-lib = import "${inputs.microvm}/lib" { inherit lib; };
  defaultRunner = microvm-lib.buildRunner {
    inherit pkgs;
    inherit (config.system.build) toplevel;
    microvmConfig = config.microvm // {
      hypervisor = "cloud-hypervisor";
      inherit (config.networking) hostName;
    };
  };
  fixedRunner = defaultRunner.overrideAttrs (old: {
    buildCommand =
      old.buildCommand
      + ''
        sed -i -e "s/--fs /--fs 'socket=snix-store.sock,tag=snix-store' /" $out/bin/microvm-run
      '';
  });
in
{
  imports = [ "${inputs.microvm}/nixos-modules/microvm/options.nix" ];

  options.cloover.profiles.microvm = {
    enable = mkEnableOption "MicroVM profile";
    useHostStore = mkOption {
      type = types.bool;
      default = true;
    };
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
          (
            if hostConfig.cloover.networkd.macvlan.enable then
              {
                type = "macvtap";
                id = "vm-${config.networking.hostName}";
                macvtap.link = hostConfig.cloover.networkd.bridgeParentName;
                macvtap.mode = "bridge";
                mac = cfg.macAddress;
              }
            else
              builtins.throw "macvlan network must be enabled on host"
          )
        ];
        shares =
          [
            {
              tag = "journal";
              source = "journal";
              mountPoint = "/var/log/journal";
              proto = "virtiofs";
            }
          ]
          ++ map (d: rec {
            proto = "virtiofs";
            inherit (d) tag;
            source = tag;
            mountPoint = d.directory;
          }) config.cloover.state.directories;
      };

      environment.etc."machine-id".text = cfg.machineId;

      cloover.username = "mjm";
      cloover.minimal.enable = true;

      cloover.consul.enable = true;
      cloover.server.enable = true;
      cloover.server.enableGarbageCollection = false;
      cloover.spire.agent.enable = true;

      environment.etc."alloy/journal.alloy".enable = false;
      system.etc.overlay.enable = false;

      # make sure this doesn't get enabled by something by mistake
      cloover.networkd.macvlan.enable = false;
    })
    (mkIf (cfg.enable && hostConfig.cloover.microvm-host.snixStore.enable) {
      # don't want to use microvm.shares for this, because (a) there's no host
      # mountpoint, and (b) we don't want to start a normal virtiofsd for this
      fileSystems."/nix/store" = mkIf hostConfig.cloover.microvm-host.snixStore.enable (
        lib.mkForce {
          device = "snix-store";
          fsType = "virtiofs";
          neededForBoot = true;
          options = [
            "defaults"
            "x-systemd.requires=systemd-modules-load.service"
          ];
        }
      );

      microvm.runner.cloud-hypervisor = mkForce fixedRunner;
    })
    (mkIf (cfg.enable && cfg.useHostStore) {
      microvm.shares = [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          proto = "virtiofs";
        }
      ];
    })
  ];
}
