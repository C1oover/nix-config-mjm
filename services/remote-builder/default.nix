{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.remote-builder;
in
{
  options.mjm.remote-builder = {
    enable = mkEnableOption "Nix remote builder";
  };

  config = mkIf cfg.enable {
    users.users.${config.mjm.username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHWS7+ecqC11q28WuizDlFuiEYEro1gv2ZtN4fs4hayg"
    ];
  };
}
