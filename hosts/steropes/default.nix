{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "steropes";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
    neededForBoot = true;
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 8 * 1024;
    }
  ];

  mjm.consul.enable = true;
  mjm.ingress.enable = true;
  mjm.nut.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/persist";
    directories = [
      "/nix"
      "/boot"
    ];
  };

  vault-secrets.roleId = "61445b18-4ebe-027e-7bb9-2c4f6711d408";
  vault-secrets.encryptedSecretId = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACt+xO3By4ZMPKm0r4AAAAAX2taMcZbqFfeMRJ
    u78cd+lPmnyLsQboIXudeYwRphn/ovHXr7O8m9/WbyRGAlPEsP9nf7mgrWgaH2+BbESZLsw0G/d1La2
    yvBTOYe0oCP2Y6izGwxQ==
  '';

  system.stateVersion = "21.03";
}
