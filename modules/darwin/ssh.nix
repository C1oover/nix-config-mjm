{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.cloover.ssh;
in
{
  imports = [ ../common/ssh.nix ];

  config = mkIf cfg.enable {
    environment.etc."ssh/sshd_config.d/102-trusted-user-ca-keys.conf".text = ''
      TrustedUserCAKeys ${cfg.trustedKeys}
    '';
  };
}
