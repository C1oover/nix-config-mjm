{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix
  ];

  networking.hostName = "chaos";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
      "size=8G"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  fileSystems."/var/lib/private/garage/data" = {
    device = "/dev/disk/by-label/garage";
    fsType = "xfs";
  };

  swapDevices = [
    {
      device = "/nix/swap";
      size = 8 * 1024;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.garage.enable = true;
  mjm.media-server.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "a87469f6-a653-37ab-8aa4-2a1adeed567f";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAABlSeuUPPOONAyz/4EAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgZyMueB74Y3vYyetmQcSbPCFWjSbcxo11oHm9+goEnEcAEAeVL5GGStlUXJNy09
    htkL4QXwXGCrViJ02OHaJNjPNPzQoR9vLNrYi2DhDbk50qO+NsToGzByQN+42f0s1Z0Bxdqzr7eLJoK
    6nav1koikrEaBmc5VNTHUBqfPXX83hxbLzNhb9rWndh6R9wp1Nnerb8tWYI3DJMHK6BAE4ACAALAAAA
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgUY533bNIby2cCW9LnE8SOL0JLP1
    LqcYqk5v4UlVd8gP/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAADyb17I9+DGdMAj4i
    ZmxKoHdMMDIwPCAvFJy1akkKb1QTJ7LMpShLLfoIYstgt7Laja0rlFaUycEkiUYzI50XBQ6fsD+rS17
    yXU3UOky0PsvkVuArCv
  '';

  system.stateVersion = "22.11";
}
