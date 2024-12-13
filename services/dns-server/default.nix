{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.dns-server;

  familyToRecordType = family: if family == 4 then "A" else "AAAA";
  hostToRecord =
    {
      name,
      family,
      address,
    }:
    "${name}  IN  ${familyToRecordType family}  ${address}";

  hostsToRecords = concatMapStringsSep "\n" hostToRecord;
in
{
  imports = [ ./blocky.nix ];

  options.mjm.dns-server = {
    enable = mkEnableOption "DNS server";

    consulAddresses = mkOption {
      type = types.listOf types.str;
      default = [
        "10.0.2.40"
        "10.0.2.42"
        "10.0.2.43"
      ];
    };
  };

  config = mkIf cfg.enable {
    mjm.services.dns-server = { };

    services.bind = {
      enable = true;
      cacheNetworks = [
        "127.0.0.0/24"
        "10.0.0.0/8"
        "2601:282:167f:d062::/64"
      ];
      forwarders = [ "127.0.0.1 port 1053" ];

      extraOptions = ''
        dnssec-validation no;
      '';

      extraConfig = ''
        statistics-channels {
          inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
        };

        zone "consul" {
          type forward;
          forward only;
          forwarders {
            ${concatMapStringsSep "\n" (addr: "${addr} port 8600;") cfg.consulAddresses}
          };
        };
      '';

      zones."home.mattmoriarity.com" = {
        master = true;
        file = pkgs.writeText "home.mattmoriarity.com.zone" ''
          $TTL  1m
          @   IN  SOA localhost. matt.mattmoriarity.com. (
                            1
                           1m     ; Refresh
                           1h     ; Retry
                           1w     ; Expire
                           1h )   ; Negative Cache TTL
          @   IN  NS  localhost.

          ${hostsToRecords (builtins.fromJSON (builtins.readFile ./hosts.json))}
        '';
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services.prometheus.exporters.bind = {
      enable = true;
      openFirewall = true;
    };

    services.consul.services = {
      bind = {
        port = 53;

        checks.up = {
          script.args = [
            (lib.getExe pkgs.dig)
            "@127.0.0.1"
            "google.com"
          ];
          intervalSeconds = 10;
          timeoutSeconds = 5;
        };
      };

      bind-exporter = {
        inherit (config.services.prometheus.exporters.bind) port;

        metrics.enable = true;

        checks.up = {
          http.path = "/";
          intervalSeconds = 30;
        };
      };
    };

    deployment.consulChecks = [ "bind" ];
  };
}
