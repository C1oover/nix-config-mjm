{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "brontes";

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

  vault-secrets.roleId = "3c25aad2-394f-9d07-2885-ebe80f05e9db";
  vault-secrets.encryptedSecretId = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADC1yEiiunq+Pmlx2oAAAAA0oMov8JY9GjeLIy
    eykXix0Xg8lswpVN+i/NZFPMNdlZP6QH4RMGyIozLIuOQS1MuTenn8AkJHkdfzihKiKr/Vl5B3L7EW0
    JDZfXo247zS2r/9otr6Q==
  '';

  system.stateVersion = "21.03";
}
