{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix
  ];

  networking.hostName = "alecto";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/nixos";
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
    enableImpermanence = true;
    persistDir = "/persist";
    directories = [ "/nix" ];
  };
  mjm.vault = {
    enable = true;
    encryptedUnsealTokens = [
      ''
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAAAd/ExIHWxfI6IjJ7AAAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAgRM6NRABdh2dgyGf8ng0snCbwhltuU9tRBvT0d863lT0AECTcT1qrxCVDLyhExW
        e5Z/AariLYL+iV05xHFx+6SJHpilzakNcTq931Vn7Ni1uWmLVpbojfq18k5ECvSyE0uI3YdaXdXpqNB
        0j0Xnmf6kLJkqlKJrO550q78BVDklSWh1NtYDiOhv6VHc/6NHGLu2HbpQw4qCLWTDpFAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgpua3SSnS6PYV1IMiWHnRW+AAU1B
        mq0iPiMHwdMG41rf/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAC/V7tadgpDEdg4vT
        lTYF10yEgW0GC92la82M8O+7WxwkNB8oxF/8MRpLB8f5FNLjQHkKHKjX5uAb2YPURHh1fcoJNI9cFjP
        3R32BAxrdW7zOowEkYdpaHlwOhm3VY=
      ''
      ''
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAAANIz5gIMENC8hETqUAAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAgnHz4WmQvszyB5gJQBvxo/c4PUxAbzsgydcsagsjWhZ4AEH1F0Fzy8138D10TJn
        MG46XAKduHMO7aioHdggPIJ0dn8Q4Bu3DccexvCYrDD8dH/zJd3CKvqC9PgYXV2+tI8DxG/j2GqiW6p
        1UrmCuhlukQbhKlF8unXu6VM05X/Y4WtV8ui2MWeiPT0/BZuranFliwMSFF1Y3/Go3IAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgUPjCU8NOdW7yxW9kG3vCKHiySsL
        Txopv3rSRIO6woOT/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAABUHi46m2Qqsa0LU5
        GSjeNZTDXFuYoR42+/l5p5ODfi8R7odHea6cShSdS78xRktXk0VH0+yLCa1LXO3769Ff8xm9ScLY/e5
        PwV5zs2BzzdGFWEYTRVfBn+I/fFr9Q=
      ''
    ];
  };

  system.stateVersion = "22.11";
}
