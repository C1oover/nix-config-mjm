{
  lib,
  config,
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
  cfg = config.mjm.profiles.microvm;

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

  options.mjm.profiles.microvm = {
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
          {
            type = "tap";
            id = "vm-${config.networking.hostName}";
            mac = cfg.macAddress;
          }
          # use macvtap in the future (probably based on whether the host
          # has macvlan enabled)
          # to use this, the big guests on the same host need to not be using
          # macvlan internally, since you can't layer macvlan in that way
          #
          # {
          #   type = "macvtap";
          #   id = "vm-${config.networking.hostName}";
          #   macvtap.link = "lan0";
          #   macvtap.mode = "bridge";
          #   mac = cfg.macAddress;
          # }
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
            # TODO maybe make this an option, if needed to disambiguate
            tag = builtins.baseNameOf d.directory;
            source = tag;
            mountPoint = d.directory;
          }) config.mjm.state.directories;
        runner.cloud-hypervisor = mkForce fixedRunner;
      };

      # don't want to use microvm.shares for this, because (a) there's no host
      # mountpoint, and (b) we don't want to start a normal virtiofsd for this
      fileSystems."/nix/store" = lib.mkForce {
        device = "snix-store";
        fsType = "virtiofs";
        neededForBoot = true;
        options = [
          "defaults"
          "x-systemd.requires=systemd-modules-load.service"
        ];
      };

      environment.etc."machine-id".text = cfg.machineId;

      mjm.username = "mjm";
      mjm.minimal.enable = true;

      mjm.consul.enable = true;
      mjm.server.enable = true;
      mjm.server.enableGarbageCollection = false;
      mjm.spire.agent.enable = true;

      environment.etc."alloy/journal.alloy".enable = false;

      # make sure these don't get enabled by something by mistake
      mjm.networkd.macvlan.enable = false;
      mjm.networkd.bridge.enable = false;
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
