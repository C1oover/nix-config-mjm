{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.mjm.consul;
in
{
  imports = [ ./common.nix ];

  options.mjm.consul = {
    server.enable = mkEnableOption "consul server";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      mjm.consul.ipv4Address = mkDefault ''{{ . | include "name" "${config.mjm.networkd.primaryIface}" | include "type" "ipv4" | attr "address" }}'';

      services.consul.extraConfig = {
        ports.http = 8500;
        ports.https = 8501;
        ports.grpc_tls = 8503;
        tls.defaults = {
          ca_file = "/run/certs/consul/bundle.pem";
          cert_file = "/run/certs/consul/cert.pem";
          key_file = "/run/certs/consul/key.pem";
          tls_min_version = "TLSv1_3";
        };
      };

      mjm.spire.certs.consul = {
        systemd.unit = "consul.service";
        systemd.action = "reload";
        user = "consul";
      };

      systemd.services.consul.preStart = lib.mkForce (
        ''
          mkdir -m 0700 -p /var/lib/consul
          chown -R consul /var/lib/consul

          # Determine interface addresses
          getAddrOnce () {
            ip -6 addr show dev ${config.mjm.networkd.primaryIface} scope global primary mngtmpaddr \
              | awk -F '[ /\t]*' '/inet/ {print $3}' | head -n 1
          }
          getAddr () {
            ADDR="$(getAddrOnce $1)"
            LEFT=60 # Die after 1 minute
            while [ -z "$ADDR" ]; do
              sleep 1
              LEFT=$(expr $LEFT - 1)
              if [ "$LEFT" -eq "0" ]; then
                echo "Address lookup timed out"
                exit 1
              fi
              ADDR="$(getAddrOnce)"
            done
            echo "$ADDR"
          }
          echo "{" > /etc/consul-addrs.json
          delim=" "
        ''
        + lib.concatStrings (
          lib.flip map [ "advertise_addr_ipv6" ] (key: ''
            echo "$delim \"${key}\": \"$(getAddr)\"" >> /etc/consul-addrs.json
            delim=","
          '')
        )
        + ''
          echo "}" >> /etc/consul-addrs.json
        ''
      );

      networking.firewall.allowedTCPPorts = [
        8300
        8301
        8302
        8500
        8501
        8502
        8503
        8600
      ];

      networking.firewall.allowedUDPPorts = [
        8301
        8600
      ];
    }

    (mkIf cfg.server.enable {
      mjm.services.consul = { };

      ingress.virtualHosts.consul = {
        upstream = {
          service = {
            name = "consul";
            port = 8501;
          };
          tls.enable = true;
        };
      };

      services.consul = {
        webUi = true;

        extraConfig = {
          server = true;
          bootstrap_expect = 3;

          telemetry = {
            prometheus_retention_time = "1h";
            disable_hostname = true;
          };
        };
      };

      networking.firewall.allowedUDPPorts = [ 8302 ];

      networking.firewall.extraCommands = ''
        iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 8600
        iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 8600
      '';

      mjm.state.directories = [
        {
          directory = "/var/lib/consul";
          user = "consul";
          group = "root";
          mode = "0700";
        }
      ];

      deployment.tests = mkIf pkgs.stdenv.isx86_64 {
        inherit (pkgs.nixosTests) consul;
      };
    })
  ]);
}
