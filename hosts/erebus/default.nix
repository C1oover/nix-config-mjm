{ localModulesPath, ... }:
{
  imports = [ "${localModulesPath}/nixos/profiles/proxmox-vm.nix" ];

  networking.hostName = "erebus";

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

  vault-secrets.roleId = "c4b46959-af00-2f70-8e4e-3e2d8b609de0";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAADfBH0O0VTxdn51AFYAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgQo9TQ0xQ57WU8Ci2mq/VsR0/eVMv1XboORzuh9BvpHAAEKvFz/mujnIqM8QnVU
    hnuklSxqDgIS1Xv5MENQvJl7l4PVZJI3kWhTaLelESUG2hegBrHByqSdysNBr2oJ7ELN6CTzW0xW351
    0sBF0McpTM0xZ9lH/kpRVpa8DyA2f2nMRx7Miym2h+TqdYYXEGTGEn5y7EkxDyijH4bAE4ACAALAAAE
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAg5ntHwLUelS3K1BZriwzvV0eNamR
    AvEsuJP4PO1tqD7//3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAABPq7rbaZsXcEkdT7
    0BPJHkOJr695U4wVhfWegTsSICHTsouQEMxxH2GOtrBh5um05GroqjgcaTAWVIndC/PMfdFeMLXxvds
    WdBIBmZOanjCcbjq58=
  '';

  system.stateVersion = "24.11";
}
