{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cfg = config.mjm.ingress;
in
{
  ingress.virtualHosts = mkIf cfg.enable {
    proxmox = {
      upstream = {
        service.name = "proxmox";
        useSSL = true;
        ipHash = true;
      };

      enableAuthProxy = false;
    };

    containers = {
      upstream.addresses = [ "10.0.2.32:5050" ];

      enableAuthProxy = false;
    };

    git = {
      upstream.addresses = [ "10.0.2.32:80" ];

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    pages = {
      upstream.addresses = [ "10.0.2.33:80" ];
      serverAliases = [
        "*.pages.midna.dev"
        "www.midna.dev"
        "midna.dev"
      ];
      enableAuthProxy = false;
      useIPv4Proxy = true;

      extraRoutes = [
        {
          match = [ { path = [ "/.well-known/matrix/server" ]; } ];
          handle = [
            {
              handler = "static_response";
              body = builtins.toJSON { "m.server" = "chat.midna.dev:443"; };
            }
          ];
        }
        {
          match = [ { path = [ "/.well-known/matrix/client" ]; } ];
          handle = [
            {
              handler = "headers";
              response.set.Access-Control-Allow-Origin = [ "*" ];
            }
            {
              handler = "static_response";
              body = builtins.toJSON {
                "m.homeserver".base_url = "https://chat.midna.dev/";
                "org.matrix.msc3575.proxy".url = "https://chat.midna.dev";
              };
            }
          ];
        }
      ];
    };
  };
}
