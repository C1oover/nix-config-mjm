{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix
  ];

  deployment.rebootPhase = null;

  networking.hostName = "hypnos";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
      "size=24G"
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

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
    { device = "/dev/disk/by-label/swap2"; }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.gitlab-runner.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "70016bfc-5625-b729-f6f2-f08693e12c02";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAABazI3tZVXq1U7x2g0AAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgIZG6SlG2sgBtjfF+cG7XP2y1TIcsz+nS+OzTbGtOun8AEGiZ3znduim4ILRXMn
    LoqwKN0njQf4jSzq2Kc5Rb3Xo2d42oRbTy/wh7/mpkEuhC60BY8CfRv+UxmsYgDQNPVl/dz6AMBJiXm
    TyXkdrrlaZH1VQ0/b4lonH8jjc57IiwsT4joYFXPVoKHGuCj1VLejvIGsmUYBpLoUgyAE4ACAALAAAA
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgGijYbKmvdMgjuXwFTPwK+u+rW1o
    gzmwtVS4X8aMaDon/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAD2AFb/+bfIkYb+9l
    kCBxg2BfgAqCesxB6ZX2tp2HyqsY2CwGt8OmO8g0D4AtagC203iDPFu+K+kWExI71t89AjtfhnIQZZi
    05naIlHmTdu6HCpVR89
  '';

  system.stateVersion = "22.11";
}
