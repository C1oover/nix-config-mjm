{
  imports = [ ../common/optional/proxmox-vm.nix ];

  deployment.rebootPhase = "vault";

  networking.hostName = "tisiphone";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
    ];
  };

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
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    directories = [
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };
  mjm.vault = {
    enable = true;
    encryptedUnsealTokens = [
      ''
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAABYQZLnQCJ5ZoF9nFUAAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAgMzuBQjxGJCoIuKOGihYvZbhH0OnT3zVJ8ZI1weREnHkAED+D6FQsviXlpL4uKk
        6eSeN9PPG/cXkHspSxqFRxkedJ9hD+s3MADtMOzAIrytxms7LoeP2X8kK0qVi6eyKaA1qeHOWYBUtFI
        g1ESASLzy5e4UtkpRITUarPY89Nb8MK9OW71CIw5rNQ/Du+y8aubFVu7haerKn4ULNBAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgXRVMT1CKcLABDzWa9Jv3VhBBs9j
        IxzLQ+NkM6iu8wx7/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAB5hDATqTiCsvclRE
        YE7U7cThF0fOjww0qxOW5A4Pjo2R0oTSw1UyYQsF63lMTtSBvhhN0fAnIubOyaWswRYjusEalmdgLDK
        /5yIoFOWzFWGOCWSRtcL6f/cP1fnmo=
      ''
      ''
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAAAK+jsm0UR7mWr1gZoAAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAgIiToor2uhH5o9PowfbfJ7ae9uLCLpsU0wSx67DdSzr4AEPt1aGtrts/8OutYkr
        g7Gru9DGIDX0Ps4+dONsxioyxCWPXopgk01fU3jVd8H3g6b1LJ0/xLOEDMVaq0flPK0rmjNpMrfwZPs
        sHn4RQYnnkGzZ3+yuW6eDdQlnp9NKYfN5iIWsp1xBpPWopEWEXAcpIkemI/jmBMmkMjAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgi58JYjGo+UXDi2mATZi/zxMN/33
        W5+M8+2cGCYVXf+j/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAADw6Fwm5E3QvPmIw3
        fxd+ufykS/CC8YkohZZSegyXYWD7Qiic4OTz41fkSIuFQRbeJ+EZfarqt1lN6cBSVIAbr+BbxY3u8pc
        Yc/kCfVbboLOmYRIy94e+aFbOTkElk=
      ''
    ];
  };

  vault-secrets.roleId = "58fe9a5f-99d1-0411-8063-4f52ca8979a9";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAAB2kfXnvn4f1ARdw/oAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgT6a/uZZJhkSss4ClVr6gvRZx+jB6fpyFdCYXAt4YMaUAEClK+aJzVxku0FrrPZ
    P/qne5w/KcKDn+IOxeQYuOeqbM0LpUVkmm8weOGFghNrfU3/y85LIZlVOz73vtSkTQG3VdsVb4SKn69
    YIeIX1zHljqowUu+XBCIQauZrpj1veUt8dkaKmnl/ms2+UYCwJ8dCbQ7g7tL/p349YLAE4ACAALAAAA
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgzJIMK/+ecAz63UWBc2g71JwnI2K
    1TOx34U2q4dlwagb/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAB5yMCTiHqCoLwj3C
    L1k1l6aJWZcwbLSJDKexvvoplbml3djzd5knc6L5bEnMzkcN8AlZv37/uLre8Y3lAh4EJ3hhD7BkDSH
    n+7NKUHuJmzlNkpGrfU
  '';

  system.stateVersion = "22.11";
}
