{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos

    ./services/nginx.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  networking.hostName = "nyx";
  networking.domain = "mattmoriarity.com";

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    ''ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGUN/c2PaYqQKsu0lgO6O8aeHZA4iT3OopYjyMs+IKokbZZTaHuMibstCYsUyztv8KacbDQ9oqnPu54rDgoZ+jw= YubiKey #16946830 PIV Slot 9a''
  ];

  services.tailscale.enable = true;

  system.stateVersion = "23.11";
}
