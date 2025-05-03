{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.userborn;
in
{
  options.mjm.userborn = {
    enable = mkEnableOption "userborn" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    system.etc.overlay.enable = true;

    # known reasons this can't be done yet:
    # - ssh keys get generated and placed in /etc
    # - consul ipv6 address is generated at runtime and placed at /etc/consul-addrs.json
    # these could probably be addressed at some point, by putting things in /run and
    # leaving symlinks in /etc where needed.
    #
    # system.etc.overlay.mutable = !config.mjm.minimal.enable;

    services.userborn = {
      enable = true;
      passwordFilesLocation = "/var/lib/nixos";
    };
  };
}
