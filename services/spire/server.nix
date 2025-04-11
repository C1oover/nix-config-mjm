{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.spire;

  configFile = pkgs.writeText "spire.hcl" ''
    server {
      trust_domain = "home.mattmoriarity.com"
      data_dir = "/var/lib/spire-server"
      jwt_issuer = "https://spire.midna.dev"
      socket_path = "/run/spire-server/api.sock"

      # one hour is a bit too unforgiving for these for me,
      # since i'm using join tokens which can't just reattest
      agent_ttl = "6h"
    }

    telemetry {
      Prometheus {
        port = 8082
      }
    }

    plugins {
      DataStore "sql" {
        plugin_data {
          database_type = "postgres"
          connection_string = "dbname=spire-server host=/run/postgresql"
        }
      }
      NodeAttestor "join_token" {
        plugin_data {}
      }
      KeyManager "disk" {
        plugin_data {
          keys_path = "/var/lib/spire-server/keys.json"
        }
      }
      UpstreamAuthority "disk" {
        plugin_data {
          cert_file_path = "/var/lib/spire-server/root.crt"
          key_file_path = "/var/lib/spire-server/root.key"
        }
      }
    }
  '';
in
{
  options.mjm.spire.server = {
    enable = mkEnableOption "SPIRE server";
  };

  config = mkIf cfg.server.enable {
    mjm.services.spire = {
      postgresql = {
        enable = true;
        databases = [ "spire-server" ];
      };
    };
    # mjm.state.services = [ "spire-server" ];
    mjm.state.directories = [
      {
        directory = "/var/lib/private/spire-server";
        user = "nobody";
        group = "nogroup";
      }
    ];

    systemd.services.spire-server = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];
      preStart = ''
        if [ ! -e /var/lib/spire-server/root.crt ]; then
          ${pkgs.openssl}/bin/openssl req \
            -subj "/C=/ST=/L=/O=/CN=home.mattmoriarity.com" \
            -newkey rsa:2048 -nodes -keyout /var/lib/spire-server/root.key \
            -x509 -days 365 -out /var/lib/spire-server/root.crt
        fi
      '';
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkgs.spire-server}/bin/spire-server run -config ${configFile}";
        StateDirectory = "spire-server";
        RuntimeDirectory = "spire-server";
        DynamicUser = true;
      };
    };

    networking.firewall.allowedTCPPorts = [
      8081
      8082
    ];

    environment.systemPackages = [
      pkgs.spire-server
      (pkgs.writeShellScriptBin ",spire" ''
        set -o errexit
        ${pkgs.spire-server}/bin/spire-server "$@" -socketPath /run/spire-server/api.sock
      '')
    ];
  };
}
