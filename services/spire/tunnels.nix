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
    mkIf
    mkMerge
    mkOption
    optional
    pipe
    types
    ;
  cfg = config.mjm.spire;

  mkSocket = name: tunnel: {
    name = "${name}-tunnel";
    value = {
      wantedBy = [ "sockets.target" ];
      partOf = [ "${name}-tunnel.service" ];
      bindsTo = mkIf (tunnel.namespace != null) [ "netns-bridge@${tunnel.namespace}.service" ];
      startLimitIntervalSec = 0;
      socketConfig = {
        FileDescriptorName = "ghostunnel";
        ListenStream =
          if tunnel.listen != null then
            tunnel.listen
          else if tunnel.mode == "server" then
            "[::]:${toString tunnel.port}"
          else if tunnel.port != null then
            "[::1]:${toString tunnel.port}"
          else if tunnel.socket != null then
            tunnel.socket
          else
            builtins.throw "missing port or socket for tunnel";
        NetworkNamespacePath = mkIf (
          tunnel.namespace != null && tunnel.mode == "client"
        ) "/run/netns/${tunnel.namespace}";
      };
    };
  };

  mkService = name: tunnel: {
    name = "${name}-tunnel";
    value = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "${name}-tunnel.socket"
      ];
      requires = [ "${name}-tunnel.socket" ];
      bindsTo = mkIf (tunnel.namespace != null) [ "netns-bridge@${tunnel.namespace}.service" ];

      environment.SPIFFE_ENDPOINT_SOCKET = "unix:${cfg.agent.socketPath}";

      startLimitIntervalSec = 0;

      serviceConfig = {
        Type = "notify-reload";
        ExecStart = utils.escapeSystemdExecArgs (
          [
            "${pkgs.ghostunnel}/bin/ghostunnel"
            tunnel.mode
            "--listen=systemd:ghostunnel"
            "--target=${tunnel.target}"
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
        NetworkNamespacePath = mkIf (tunnel.namespace != null) "/run/netns/${tunnel.namespace}";
      };
    };
  };
in
{
  options.mjm.spire.tunnels = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            mode = mkOption {
              type = types.enum [
                "client"
                "server"
              ];
            };
            namespace = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            listen = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            port = mkOption {
              type = types.nullOr types.port;
              default = null;
            };
            socket = mkOption {
              type = types.nullOr types.path;
              default = null;
            };
            openFirewall = mkOption {
              type = types.bool;
              default = config.port != null;
            };
            target = mkOption {
              type = types.str;
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
            allowedServices = mkMerge [
              (mkIf config.allowIngress [ "caddy" ])
              (mkIf config.allowMetrics [ "prometheus" ])
            ];
          };
        }
      )
    );
  };

  config = mkIf (cfg.tunnels != { }) {
    mjm.spire.agent.enable = true;
    systemd.services = mapAttrs' mkService cfg.tunnels;
    systemd.sockets = mapAttrs' mkSocket cfg.tunnels;
    networking.firewall.allowedTCPPorts = pipe cfg.tunnels [
      attrValues
      (filter (t: t.openFirewall))
      (map (t: t.port))
    ];
  };
}
