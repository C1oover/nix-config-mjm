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
      socketConfig = {
        FileDescriptorName = "ghostunnel";
        ListenStream = "[::]:${toString tunnel.port}";
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

      environment.SPIFFE_ENDPOINT_SOCKET = "unix:${cfg.agent.socketPath}";

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
          ++ optional (tunnel.allowedServices == [ ]) "--disable-authentication"
          ++ (map (s: "--allow-uri=spiffe://home.mattmoriarity.com/svc/${s}") tunnel.allowedServices)
        );
        DynamicUser = true;
        Restart = "always";
        WatchdogSec = 1;
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
            port = mkOption {
              type = types.port;
            };
            openFirewall = mkOption {
              type = types.bool;
              default = true;
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
          };

          config = {
            allowedServices = mkIf config.allowIngress [ "caddy" ];
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
