{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
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
    mjm.state.directories = [ "/var/lib/libvirt" ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    users.users.${config.mjm.username}.extraGroups = [ "libvirtd" ];
  };
}
