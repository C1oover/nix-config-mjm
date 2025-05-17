{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMap
    concatStringsSep
    map
    mapAttrs'
    mapAttrsToList
    mkMerge
    mkIf
    mkOption
    pipe
    replaceStrings
    types
    ;
  cfg = config.mjm.spire;

  secretName = svc: path: "${svc}_${replaceStrings [ "/" ] [ "__" ] path}";

  credServiceType = serviceName: types.attrsOf (credKeyType "${serviceName}.service");

  credKeyType =
    unit:
    types.submodule (
      {
        name,
        config,
        options,
        ...
      }:
      let
        svcName = lib.last (lib.dropEnd 2 options.name.loc);
      in
      {
        options = {
          name = mkOption {
            type = types.str;
            default = secretName svcName name;
          };
          path = mkOption {
            type = types.path;
            default = "/run/credentials/${unit}/${config.name}";
          };
          loadCredential = mkOption {
            type = types.str;
            default = "${config.name}:/run/${svcName}-creds.sock";
          };
        };
      }
    );
in
{
  options.mjm.spire.creds = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule {
        options = {
          aliases = mkOption {
            type = types.attrsOf types.str;
            default = { };
          };
        };
      }
    );
  };

  options.systemd.services = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options.credentials = mkOption {
            default = { };
            type = types.attrsOf (credServiceType name);
          };

          config = mkIf (config.credentials != { }) {
            serviceConfig.LoadCredential = pipe config.credentials [
              attrValues
              (concatMap attrValues)
              (map (x: x.loadCredential))
            ];
          };
        }
      )
    );
  };

  config = mkIf cfg.agent.enable (mkMerge [
    {
      systemd.services."spiffe-creds@" = {
        description = "SPIFFE Credentials Helper for '%i'";
        requires = [ "spiffe-creds@%i.socket" ];
        after = [
          "network.target"
          "spiffe-creds@%i.socket"
        ];

        environment = {
          SPIFFE_ENDPOINT_SOCKET = "unix:${cfg.agent.socketPath}";
          VAULT_ADDR = "https://vault.service.consul:8200";
        };

        serviceConfig = {
          Type = "notify";
          ExecStart = concatStringsSep " " [
            "${pkgs.spiffe-tool}/bin/spiffe-creds"
            "--path"
            "prod/services/%i"
            "serve"
          ];
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
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
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
          UMask = "0077";
        };
      };

      systemd.sockets."spiffe-creds@" = {
        description = "SPIFFE Credentials Helper Socket for '%i'";
        partOf = [ "spiffe-creds@%i.service" ];
        socketConfig = {
          ListenStream = "/run/%i-creds.sock";
          SocketMode = "0600";
        };
      };
    }

    (mkIf (cfg.creds != { }) {
      systemd.services = mapAttrs' (
        name:
        { aliases, ... }:
        {
          name = "spiffe-creds@${name}";
          value = {
            overrideStrategy = "asDropin";
            environment.SECRET_ALIASES = concatStringsSep " " (mapAttrsToList (k: v: "${k}=${v}") aliases);
          };
        }
      ) cfg.creds;
    })
  ]);
}
