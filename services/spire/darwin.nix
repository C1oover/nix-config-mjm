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
    optionalString
    types
    ;
  cfg = config.mjm.spire;

  dataDir = "/Library/Application Support/SPIRE";

  configFile = pkgs.writeText "agent.hcl" ''
    agent {
      trust_domain = "home.mattmoriarity.com"
      data_dir = "${dataDir}"
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
          directory = "${dataDir}"
        }
      }
      WorkloadAttestor "unix" {
        plugin_data {}
      }
    }
  '';
in
{
  options.mjm.spire.agent = {
    enable = mkEnableOption "SPIRE agent";

    serverAddress = mkOption {
      type = types.str;
      default = "arges.home.mattmoriarity.com";
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
    launchd.daemons.spire-agent = {
      command = "${pkgs.spire-agent}/bin/spire-agent run -config ${configFile}";
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Library/Logs/spire-agent.log";
        StandardErrorPath = "/Library/Logs/spire-agent.log";
      };
    };

    # users.users.spire-agent = {
    #   isSystemUser = true;
    #   group = "spire-agent";
    # };
    # users.groups.spire-agent = { };

    services.consul.services.spire-agent = {
      metrics.enable = true;
      metrics.port = 9988;

      checks.up = {
        http.path = "/ready";
        http.port = 18080;
      };
    };

    environment.systemPackages = [
      pkgs.spire-agent
      (pkgs.writeShellScriptBin ",spire" ''
        set -o errexit
        ${pkgs.spire-agent}/bin/spire-agent "$@" -socketPath ${cfg.agent.socketPath}
      '')
    ];
  };
}
