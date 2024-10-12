{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix
  ];

  networking.hostName = "aether";

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
    options = [
      "fmask=077"
      "dmask=077"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "xfs";
    neededForBoot = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.dns-server.enable = true;
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

  vault-secrets.roleId = "db2e0376-0645-c858-80b5-2b5b29476c24";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAACeDojsrsbKgYcW2i0AAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgZQIN3f/06YN9TSB1ienCJhW9YsR2z7pgAnLnABXUmIQAEMgUmsLA3pW/PQlmvG
    +D06Pq/ZKNsDIl2vAbLBQdqyKm90ynUJrFVxDhZjRoTEdJPL37jjkW4r3ZytHIzlm8HZJXfeazSvXLn
    BlvuGRqJ3t5s7TS0acqOctdPS2lSnFwjRPIDEdiHADjS1PUUo2iX2dIfZJ+Zs86JC1rAE4ACAALAAAE
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgYS6xE/oKaJqJOLZ0YyVD3+Gn/la
    ZY+l/r5ChZfxg8cX/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAACoVaM/3hZYjTfeSb
    3MptG2prfnpvAR2vNPYmJTzIEiLZxr9QxrGo4g075g57jLLZxVqRLInr6qpm5D1E+69AJOUUeU2xo2B
    frqb69Hvi8N7+M+w7c=
  '';

  system.stateVersion = "24.11";
}
