{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")

    ../common/global/nixos.nix

    ../common/optional/consul-agent.nix
    ./services/lldap.nix
  ];

  networking.hostName = "orion";

  # Supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  services.consul.interface.advertise = "eth0";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
