{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.cloover.ssh;
in
{
  imports = [ ../common/ssh.nix ];

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      extraConfig = ''
        TrustedUserCAKeys ${cfg.trustedKeys}
      '';
    };
  };
}
