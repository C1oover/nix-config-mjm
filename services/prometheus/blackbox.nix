{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.prometheus;

  jsonFormat = pkgs.formats.json { };
  dnsServers = jsonFormat.generate "dns-servers.json" [
    { targets = cfg.dnsServers; }
  ];
  publicDns = jsonFormat.generate "public-dns-servers.json" [
    {
      targets = [
        "8.8.4.4"
        "8.8.8.8"
        "1.0.0.1"
        "1.1.1.1"
      ];
    }
  ];
in
{
  config = mkIf cfg.enable {
    environment.etc."alloy/blackbox.alloy".source = ./blackbox.alloy;
    environment.etc."alloy/blackbox-config.alloy".text = ''
      local.file "blackbox_config" {
        filename = "${./blackbox.yml}"
      }

      discovery.file "local_dns" {
        files = ["${dnsServers}"]
      }

      discovery.file "public_dns" {
        files = ["${publicDns}"]
      }
    '';
  };
}
