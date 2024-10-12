{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "arges";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
      "size=20G"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    options = [
      "bind"
      "X-fstrim.notrim"
    ];
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 20 * 1024;
    }
  ];

  mjm.consul.enable = true;
  mjm.nut = {
    enable = true;
    mode = "server";
  };
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    directories = [ "/boot" ];
  };
  mjm.userborn.enable = true;

  # TODO consider if this should be in services/
  # remote builder key
  users.users.matt.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHWS7+ecqC11q28WuizDlFuiEYEro1gv2ZtN4fs4hayg"
  ];

  vault-secrets.roleId = "841fdaf1-6a2d-f471-ad85-ae485c232b89";
  vault-secrets.encryptedSecretId = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACe8V46fSAKj3ptq8AAAAAA82YPKSCP+ruRutt
    K5vro3AJJVMS2PIgNH3TixozRFDCxxO1rNgBjZCy59/aIl1bMjwuPkzm1IQC9M68HHMcPicPQ0SBNei
    oOP8w1f+v5P/NWgYydaw==
  '';

  system.stateVersion = "21.03";
}
