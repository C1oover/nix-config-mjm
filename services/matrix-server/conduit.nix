{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.matrix-server;
  pkg = (import inputs.conduit).packages.${pkgs.system}.default;
in
{
  options.mjm.matrix-server = {
    enable = mkEnableOption "matrix server";
  };

  config = mkIf cfg.enable {
    mjm.services.matrix-server = { };
    mjm.state.directories = [ "/var/lib/private/matrix-conduit" ];

    ingress.virtualHosts.chat = {
      upstream.service.name = "conduit";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.matrix-conduit = {
      enable = true;
      package = pkg;

      settings.global = {
        address = "::";
        server_name = "midna.dev";
        database_backend = "rocksdb";
        log = "info";
        # default denylist, but without the local addresses so that we can send
        # messages to the bridges
        ip_range_denylist = [
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
          "192.0.0.0/24"
          "169.254.0.0/16"
          "192.88.99.0/24"
          "198.18.0.0/15"
          "192.0.2.0/24"
          "198.51.100.0/24"
          "203.0.113.0/24"
          "224.0.0.0/4"
          "fe80::/10"
          "fc00::/7"
          "2001:db8::/32"
          "ff00::/8"
          "fec0::/10"
        ];
        new_user_displayname_suffix = "";
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.matrix-conduit.settings.global.port ];

    services.consul.services.conduit = rec {
      inherit (config.services.matrix-conduit.settings.global) port;

      checks = [
        {
          name = "conduit is ready";
          http = "http://localhost:${toString port}/_matrix/client/versions";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };
  };
}
