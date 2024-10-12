{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix
  ];

  networking.hostName = "helios";

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
  mjm.matrix-server.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "61d175e1-7a2e-4554-2cca-cff48c926b82";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAACMSlwgU4cht9d/8poAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgyrHwXPgmLRSfnWmVOVadmQsfrWwNmn8rotDBuVJu8LkAEBAt22MCDqTcF1ad61
    oYAkv8vqoHoql9hhULLI7md1w/8jrTVTlvyrJ/H8YNcJemQIVKWiomlNGu39GjQx5YquYl4tHhsCbKC
    ujHDDG+PFtPQ/3cGfANz7fyD3ur149hedxOD5O3LeeCFMQEUnZs2JYUAZq58ZcctQX8AE4ACAALAAAA
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgCo54O1NoIVzheq2tIrr5nK2NCEY
    yHi1z9RZtfNNGIkn/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAA9luYJlP0l8cE8vi
    eHb/LhiKxlW/kGF3Z9I2bpvpRNP3FSZk1PF/AWY5p7YmXSmggVxEkHrxj1biiIsHF0ZcpVblnFJWDQK
    Rgv8rmR2IfHnvdOEgmj
  '';

  system.stateVersion = "22.11";
}
