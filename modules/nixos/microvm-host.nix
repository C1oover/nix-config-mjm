{
  lib,
  config,
  pkgs,
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
    mkAfter
    mkBefore
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkOverride
    optionalString
    types
    ;
  cfg = config.mjm.microvm-host;

  snix = (import inputs.snix { localSystem = pkgs.system; }).snix;
  snixAddr = "grpc+unix:///run/vm-store.sock";
  snixAddrArgs = "--blob-service-addr ${snixAddr} --directory-service-addr ${snixAddr} --path-info-service-addr ${snixAddr}";
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
            hostConfig = config;
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

  config = mkIf cfg.enable (mkMerge [
    {
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

      # TODO probably remove eventually
      environment.systemPackages = [ snix.store ];

      systemd.services.snix-store = {
        after = [
          "network.target"
          "snix-store.socket"
        ];
        requires = [ "snix-store.socket" ];

        environment.OTEL_SERVICE_NAME = "snix-store";
        environment.OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";

        serviceConfig = {
          Type = "exec";
          ExecStart = "${snix.store}/bin/snix-store daemon -l sd-listen";
          StateDirectory = "snix-store";
          DynamicUser = true;

          CapabilityBoundingSet = "";
          DevicePolicy = "closed";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateIPC = true;
          PrivateUsers = "identity";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [ "AF_INET" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          SystemCallErrorNumber = "EPERM";
          SystemCallFilter = [
            "@system-service"
            "~@resources @privileged"
          ];
          UMask = "0077";
        };
      };

      systemd.sockets.snix-store = {
        wantedBy = [ "sockets.target" ];
        partOf = [ "snix-store.service" ];
        socketConfig = {
          ListenStream = "/run/vm-store.sock";
        };
      };

      systemd.services."microvm-snix-store@" = {
        after = [ "snix-store.socket" ];
        wants = [ "snix-store.socket" ];
        before = [ "microvm@%i.service" ];
        partOf = [ "microvm@%i.service" ];

        restartIfChanged = false;

        environment.OTEL_SERVICE_NAME = "snix-store-virtiofs";
        environment.OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod,microvm.name=%i";

        serviceConfig = {
          ExecStart = "${snix.store}/bin/snix-store virtiofs --list-root ${snixAddrArgs} /var/lib/microvms/%i/snix-store.sock";
          Type = "exec";
          Restart = "always";
          RestartSec = "5s";
          Group = "kvm";

          DevicePolicy = "closed";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateIPC = true;
          PrivateTmp = true;
          PrivateUsers = "identity";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          SystemCallErrorNumber = "EPERM";
          SystemCallFilter = [
            "@system-service"
            "~@resources @privileged"
          ];
          UMask = "0007";
        };
      };

      systemd.services."microvm@" = {
        requires = [ "microvm-snix-store@%i.service" ];
        serviceConfig.TimeoutSec = mkOverride 55 300;
      };
    }
    {
      systemd.services = concatMapAttrs (name: vm: {
        "install-microvm-${name}" = {
          wants = [ "snix-store.socket" ];
          after = [ "snix-store.socket" ];
          path = [
            config.boot.zfs.package
            config.nix.package
            pkgs.jq
            snix.store
          ];
          script = mkMerge [
            (mkBefore (
              concatMapStringsSep "\n" (
                share:
                optionalString (!(hasPrefix "/" share.source)) ''
                  zfs create -p ${cfg.zfsPrefix}/microvms/${name}/${share.source}
                ''
              ) vm.config.config.microvm.shares
            ))
            (mkAfter ''
              nix path-info --json --closure-size --recursive ./toplevel | \
                jq -s '{closure: add}' | \
                snix-store copy ${snixAddrArgs} -
            '')
          ];
        };
        "microvm-snix-store@${name}" = {
          serviceConfig.X-RestartIfChanged = [
            ""
            vm.restartIfChanged
          ];
          path = lib.mkForce [ ];
          overrideStrategy = "asDropin";
        };
      }) config.microvm.vms;
    }
  ]);
}
