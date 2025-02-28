{ config, lib, ... }:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.mjm.consul;
in
{
  options.mjm.consul = {
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

  config = mkIf cfg.enable (mkMerge [
    {
      services.consul = {
        enable = true;

        extraConfig = {
          auto_reload_config = true;

          retry_join = lib.mkDefault [
            "megaera.home.mattmoriarity.com"
            "tisiphone.home.mattmoriarity.com"
            "alecto.home.mattmoriarity.com"
          ];

          client_addr = "0.0.0.0";
          bind_addr = mkDefault "[::]";
          advertise_addr_ipv4 = cfg.ipv4Address;
          advertise_addr = cfg.ipv4Address;

          ports.grpc = 8502;

          enable_local_script_checks = true;

          node_meta = mkIf (cfg.tailscaleIp != null) { tailscale_ip = cfg.tailscaleIp; };
        };
      };
    }
  ]);
}
