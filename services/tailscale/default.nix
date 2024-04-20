{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.tailscale;
in
{
  options.mjm.tailscale = {
    enable = mkEnableOption "tailscale";

    ip = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    mjm.state.directories = [ "/var/lib/tailscale" ];
    deployment.tags = [ "svc-tailscale" ];

    services.tailscale.enable = true;

    services.consul.extraConfig = mkIf (cfg.ip != null) { node_meta.tailscale_ip = cfg.ip; };

    systemd.network.networks."05-tailscale" = {
      matchConfig.Name = "tailscale*";
      linkConfig = {
        Unmanaged = true;
        ActivationPolicy = "manual";
      };
    };
  };
}
