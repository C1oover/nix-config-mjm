{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.consul-agent;
in
{
  options.mjm.consul-agent = {
    enable = mkEnableOption "consul agent";

    tailscaleIp = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    ipv4Address = mkOption {
      type = types.str;
      default = ''{{ GetDefaultInterfaces | include "type" "ipv4" | attr "address" }}'';
    };
  };

  config = mkIf cfg.enable {
    services.consul = {
      enable = true;

      extraConfig = {
        retry_join = lib.mkDefault [
          "10.0.2.40"
          "10.0.2.42"
          "10.0.2.43"
        ];

        client_addr = "0.0.0.0";
        bind_addr = "[::]";
        advertise_addr_ipv4 = cfg.ipv4Address;

        ports.grpc = 8502;
        connect.enabled = true;

        node_meta = mkIf (cfg.tailscaleIp != null) { tailscale_ip = cfg.tailscaleIp; };
      };
    };

    systemd.services.consul.preStart = lib.mkForce (
      ''
        mkdir -m 0700 -p /var/lib/consul
        chown -R consul /var/lib/consul

        # Determine interface addresses
        getAddrOnce () {
          ip -6 addr show scope global primary \
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
        lib.flip map
          [
            "advertise_addr"
            "advertise_addr_ipv6"
          ]
          (
            key: ''
              echo "$delim \"${key}\": \"$(getAddr)\"" >> /etc/consul-addrs.json
              delim=","
            ''
          )
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
      8502
      8503
      8600
    ];

    networking.firewall.allowedUDPPorts = [
      8301
      8600
    ];
  };
}
