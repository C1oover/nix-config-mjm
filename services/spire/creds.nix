{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs'
    mapAttrsToList
    mkMerge
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.spire;
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
            (lib.getExe pkgs.spire-secrets)
            "-path"
            "prod/services/%i"
            "server"
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
            environment.SECRET_ALIASES = concatStringsSep " " (mapAttrsToList (k: v: "${k}:${v}") aliases);
          };
        }
      ) cfg.creds;
    })
  ]);
}
