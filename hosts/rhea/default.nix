{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")

    ../common/global/nixos
  ];

  networking.hostName = "rhea";

  # Supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  mjm.consul = {
    enable = true;
    ipv4Address = "10.0.2.47";
  };
  mjm.dns-server.enable = true;
  mjm.server.enable = true;
  mjm.server.enableSSHHostCert = false;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
