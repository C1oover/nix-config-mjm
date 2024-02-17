{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-server.nix
    ../common/optional/vault-server.nix
    ../common/optional/nix-remote.nix
  ];

  networking.hostName = "alecto";

  boot.loader.grub = {
    enable = true;
    mirroredBoots = [
      {
        devices = [ "/dev/sda" ];
        path = "/persist/boot";
      }
    ];
    copyKernels = true;
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
