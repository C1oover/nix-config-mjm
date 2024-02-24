{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/vault-server.nix
  ];

  networking.hostName = "megaera";

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

  mjm.consul-agent = {
    enable = true;
    server.enable = true;
  };

  system.stateVersion = "22.11";
}
