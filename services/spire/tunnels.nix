{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    map
    mapAttrs'
    mkDefault
    mkIf
    mkMerge
    mkOption
    optional
    optionalString
    pipe
    types
    ;
  cfg = config.cloover.spire;

  mkSocket =
    name: tunnel:
    let
      inherit (tunnel) mode listen;
    in
    {
      name = "${name}-tunnel";
      value = {
        description = "${if mode == "server" then "Server" else "Client"} Tunnel '${name}' Socket";
        wantedBy = if listen.early then [ "network.target" ] else [ "sockets.target" ];
        partOf = [ "${name}-tunnel.service" ];
        startLimitIntervalSec = 0;
        unitConfig = mkIf listen.early {
          DefaultDependencies = false;
        };
        socketConfig = {
          FileDescriptorName = "ghostunnel";
          ListenStream = tunnel.listen.address;
        };
      };
    };

  mkService =
    name: tunnel:
    let
      inherit (tunnel) mode target;
    in
    {
      name = "${name}-tunnel";
      value = {
        description = "${if mode == "server" then "Server" else "Client"} Tunnel '${name}'";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "${name}-tunnel.socket"
        ];
        requires = [ "${name}-tunnel.socket" ];

        environment.SPIFFE_ENDPOINT_SOCKET = "unix:${cfg.agent.socketPath}";

        startLimitIntervalSec = 0;

        serviceConfig = {
          Type = "notify-reload";
          ExecStart = utils.escapeSystemdExecArgs (
            [
              "${pkgs.ghostunnel}/bin/ghostunnel"
              tunnel.mode
              "--listen=systemd:ghostunnel"
              "--target=${target.address}"
              "--use-workload-api"
            ]
            ++ (
              if tunnel.mode == "server" then
                (
                  optional (tunnel.allowedServices == [ ]) "--disable-authentication"
                  ++ (map (s: "--allow-uri=spiffe://home.mattmoriarity.com/svc/${s}") tunnel.allowedServices)
                )
              else
                [ "--verify-uri=spiffe://home.mattmoriarity.com/svc/${tunnel.service}" ]
            )
          );
          DynamicUser = true;
          Restart = "always";
          WatchdogSec = 1;

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
    };

  mkEntry = name: tunnel: {
    name = "tunnel-${name}";
    value = {
      spiffe_id = "spiffe://${config.cloover.spire.agent.trustDomain}/svc/${tunnel.id}";
      selectors = [
        {
          type = "systemd";
          value = "id:${name}-tunnel.service";
        }
      ];
      dns_names = mkIf (tunnel.mode == "server") [ "${tunnel.id}.service.consul" ];
    };
  };
in
{
  options.cloover.spire.tunnels = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            id = mkOption {
              type = types.str;
            };
            mode = mkOption {
              type = types.enum [
                "client"
                "server"
              ];
            };
            listen = {
              port = mkOption {
                type = types.nullOr types.port;
                default = null;
              };
              socket = mkOption {
                type = types.nullOr types.path;
                default = null;
              };
              address = mkOption {
                type = types.str;
              };
              early = mkOption {
                type = types.bool;
                default = false;
              };
            };
            target = {
              port = mkOption {
                type = types.nullOr types.port;
                default = null;
              };
              host = mkOption {
                type = types.nullOr types.str;
                default = "localhost";
              };
              service = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              socket = mkOption {
                type = types.nullOr types.path;
                default = null;
              };
              address = mkOption {
                type = types.str;
              };
            };
            openFirewall = mkOption {
              type = types.bool;
              default = config.listen.port != null;
            };
            allowedServices = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            allowIngress = mkOption {
              type = types.bool;
              default = false;
            };
            allowMetrics = mkOption {
              type = types.bool;
              default = false;
            };
            service = mkOption {
              type = types.str;
            };
          };

          config = {
            listen.address = mkMerge [
              (mkIf (config.listen.port != null)
                "[::${optionalString (config.mode == "client") "1"}]:${toString config.listen.port}"
              )
              (mkIf (config.listen.socket != null) config.listen.socket)
            ];

            target.host = mkIf (config.target.service != null) "${config.target.service}.service.consul";

            target.address = mkMerge [
              (mkIf (config.target.port != null) "${config.target.host}:${toString config.target.port}")
              (mkIf (config.target.socket != null) "unix:${config.target.socket}")
            ];

            allowedServices = mkMerge [
              (mkIf config.allowIngress [ "caddy" ])
              (mkIf config.allowMetrics [ "prometheus" ])
            ];

            service = mkIf (config.target.service != null) (mkDefault config.target.service);
          };
        }
      )
    );
  };

  config = mkIf (cfg.tunnels != { }) {
    cloover.spire.agent.enable = true;
    systemd.services = mapAttrs' mkService cfg.tunnels;
    systemd.sockets = mapAttrs' mkSocket cfg.tunnels;
    networking.firewall.allowedTCPPorts = pipe cfg.tunnels [
      attrValues
      (filter (t: t.openFirewall))
      (map (t: t.listen.port))
    ];
    cloover.spire.entries = mapAttrs' mkEntry cfg.tunnels;
  };
}
