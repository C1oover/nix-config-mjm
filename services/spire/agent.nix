{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalString
    types
    ;
  cfg = config.mjm.spire;

  configFile = pkgs.writeText "agent.hcl" ''
    agent {
      trust_domain = "home.mattmoriarity.com"
      data_dir = "/var/lib/spire-agent"
      socket_path = "${cfg.agent.socketPath}"
      ${optionalString (cfg.agent.joinToken != null) ''join_token = "${cfg.agent.joinToken}"''}

      server_address = "${cfg.agent.serverAddress}"
      server_port = 8081
      trust_bundle_path = "${./trust.pem}"
    }

    telemetry {
      Prometheus {
        host = "[::]"
        port = 9988
      }
    }

    health_checks {
      listener_enabled = true
      bind_port = "18080"
    }

    plugins {
      NodeAttestor "join_token" {
        plugin_data {}
      }
      KeyManager "disk" {
        plugin_data {
          directory = "/var/lib/spire-agent"
        }
      }
      WorkloadAttestor "unix" {
        plugin_data {}
      }
      WorkloadAttestor "systemd" {
        plugin_data {}
      }
      ${optionalString config.virtualisation.podman.enable ''
        WorkloadAttestor "docker" {
          plugin_data {}
        }
      ''}
    }
  '';
in
{
  options.mjm.spire.agent = {
    enable = mkEnableOption "SPIRE agent";

    serverAddress = mkOption {
      type = types.str;
      default = if cfg.server.enable then "127.0.0.1" else "arges.home.mattmoriarity.com";
    };

    joinToken = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    socketPath = mkOption {
      type = types.path;
      default = "/run/spire-agent/api.sock";
      readOnly = true;
    };
  };

  config = mkIf cfg.agent.enable {
    mjm.state.services = [ "spire-agent" ];

    users.users.spire-agent = {
      isSystemUser = true;
      group = "spire-agent";
    };
    users.groups.spire-agent = { };

    systemd.services.spire-agent = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ optional cfg.server.enable "spire-server.service";
      wants = mkIf cfg.server.enable [ "spire-server.service" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkgs.spire-agent}/bin/spire-agent run -config ${configFile}";
        StateDirectory = "spire-agent";
        RuntimeDirectory = "spire-agent";
        # https://github.com/systemd/systemd/issues/22737
        # DynamicUser = true;
        User = "spire-agent";
        Group = "spire-agent";
        SupplementaryGroups = mkIf config.virtualisation.podman.enable [ "podman" ];
        Restart = "always";
        RestartSec = "5s";

        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = "identity";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@resources @privileged"
        ];
        # spire-agent does this itself anyway
        UMask = "0027";
      };
    };

    services.consul.services.spire-agent = {
      metrics.enable = true;
      metrics.port = 9988;

      checks.up = {
        http.path = "/ready";
        http.port = 18080;
      };
    };

    networking.firewall.allowedTCPPorts = [ 9988 ];

    environment.systemPackages = [
      pkgs.spire-agent
      (pkgs.writeShellScriptBin ",spire" ''
        set -o errexit
        ${pkgs.spire-agent}/bin/spire-agent "$@" -socketPath ${cfg.agent.socketPath}
      '')
    ];
  };
}
