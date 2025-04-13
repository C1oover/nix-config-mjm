{ pkgs, ... }:
let
  buildNetworkJson = pkgs.writeNu "build-network-json" ''
    def main [
      name: string
    ] {
      {
        container_id: $name
        container_name: $name
        networks: {
          mjm-services: {
            interface_name: "eth0"
          }
        }
        network_info: {
          mjm-services: {
            dns_enabled: false
            driver: "macvlan"
            id: "mjm-services"
            internal: false
            ipv6_enabled: true
            name: "mjm-services"
            network_interface: "lan0"
            ipam_options: {driver: "dhcp"}
          }
        }
      } | to json | print
    }
  '';
in
{
  systemd.sockets.netavark-dhcp-proxy = {
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/podman/nv-proxy.sock";
      SocketMode = "0600";
    };
  };

  systemd.services.netavark-dhcp-proxy = {
    wantedBy = [ "default.target" ];
    requires = [ "netavark-dhcp-proxy.socket" ];
    after = [ "netavark-dhcp-proxy.socket" ];
    startLimitIntervalSec = 0;

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.netavark}/bin/netavark dhcp-proxy -a 30";
    };
  };

  systemd.services."netns-bridge@" = {
    after = [ "network.target" ];
    path = with pkgs; [
      iproute2
      iptables
      netavark
      procps
    ];
    environment.RUST_LOG = "debug";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "%i-netns";
      ExecStartPre = "-/usr/bin/env ip netns delete %i";
      ExecStart = [
        "/usr/bin/env ip netns add %i"
        "/bin/sh -c '${buildNetworkJson} %i | netavark -c /run/%i-netns setup /run/netns/%i'"
        "/usr/bin/env ip netns exec %i sysctl -w net.ipv6.conf.eth0.autoconf=1"
        "/usr/bin/env ip -n %i addr add 169.254.170.2/16 dev lo"
      ];
      ExecStop = "/usr/bin/env ip netns delete %i";
    };
  };
}
