{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.ipv4-proxy;
in
{
  options.cloover.ipv4-proxy = {
    enable = mkEnableOption "IPv4 proxy";
  };

  config = mkIf cfg.enable {
    cloover.services.ipv4-proxy = { };

    services.haproxy = {
      enable = true;
      config = ''
        frontend http
          bind *:80
          option tcplog
          mode tcp
          default_backend http_nodes

        frontend https
          bind *:443
          option tcplog
          mode tcp
          default_backend https_nodes

        backend http_nodes
          mode tcp
          balance roundrobin
          server persephone [${config.cloover.ipv6Prefix}:dea6:32ff:fed5:d840]:80 check

        backend https_nodes
          mode tcp
          balance roundrobin
          server persephone [${config.cloover.ipv6Prefix}:dea6:32ff:fed5:d840]:443 check
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    deployment.tests = {
      inherit (pkgs.nixosTests) haproxy;
    };
  };
}
