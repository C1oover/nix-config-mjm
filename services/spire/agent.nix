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

  configFile = pkgs.writeText "agent.hcl" ''
    agent {
      trust_domain = "home.mattmoriarity.com"
      data_dir = "/var/lib/spire-agent"
      socket_path = "/run/spire-agent/api.sock"
      ${optionalString (cfg.agent.joinToken != null) ''join_token = "${cfg.agent.joinToken}"''}

      server_address = "arges.home.mattmoriarity.com"
      server_port = 8081
      trust_bundle_path = "${./trust.pem}"
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
    }
  '';
in
{
  options.mjm.spire.agent = {
    enable = mkEnableOption "SPIRE agent";
    joinToken = mkOption {
      type = types.nullOr types.str;
      default = null;
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
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.spire-agent}/bin/spire-agent run -config ${configFile}";
        StateDirectory = "spire-agent";
        RuntimeDirectory = "spire-agent";
        # https://github.com/systemd/systemd/issues/22737
        # DynamicUser = true;
        User = "spire-agent";
        Group = "spire-agent";
      };
    };

    environment.systemPackages = [
      pkgs.spire-agent
      (pkgs.writeShellScriptBin ",spire" ''
        set -o errexit
        ${pkgs.spire-agent}/bin/spire-agent "$@" -socketPath /run/spire-agent/api.sock
      '')
    ];
  };
}
