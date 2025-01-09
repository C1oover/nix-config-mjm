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
  };
}
