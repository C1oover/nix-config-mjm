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
          retry_join = lib.mkDefault [
            "10.0.2.40"
            "10.0.2.42"
            "10.0.2.43"
          ];

          client_addr = "0.0.0.0";
          bind_addr = mkDefault "[::]";
          advertise_addr_ipv4 = cfg.ipv4Address;

          ports.grpc = 8502;

          enable_local_script_checks = true;

          node_meta = mkIf (cfg.tailscaleIp != null) { tailscale_ip = cfg.tailscaleIp; };
        };
      };
    }
  ]);
}
