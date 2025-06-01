{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.cloover.desktop;
in
{
  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };
    programs.virt-manager.enable = true;
    cloover.state.directories = [ "/var/lib/libvirt" ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
        ipv6_enabled = true;
      };
    };

    users.users.${config.cloover.username}.extraGroups = [
      "libvirtd"
      "podman"
    ];
  };
}
