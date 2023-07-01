{
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")

    ../common/global/nixos.nix

    ../common/optional/consul-agent.nix
    ../common/optional/nix-remote.nix
    ./services/prometheus
  ];

  networking.hostName = "gaia";

  # Supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  services.consul.interface.advertise = "eth0";

  # the network interface systemd service doesn't load in a container
  systemd.services.consul.after = lib.mkForce ["network.target"];
  systemd.services.consul.bindsTo = lib.mkForce [];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
