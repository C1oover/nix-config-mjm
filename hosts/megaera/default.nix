{
  imports = [
    ./secrets.nix
  ];

  networking.hostName = "megaera";

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "ext4";
    neededForBoot = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul = {
    enable = true;
    server.enable = true;
  };
  mjm.proxmox-vm.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot.enable = true;
    directories = [
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };
  mjm.vault.enable = true;

  system.stateVersion = "22.11";
}
