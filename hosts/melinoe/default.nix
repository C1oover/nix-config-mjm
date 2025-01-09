{ localModulesPath, ... }:
{
  imports = [ "${localModulesPath}/nixos/profiles/proxmox-vm.nix" ];

  mjm.username = "mjm";

  networking.hostName = "melinoe";

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "xfs";
    options = [ "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 8 * 1024;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.gitlab.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "8G";
    };
    directories = [
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };

  vault-secrets.roleId = "a1b1c0f2-15de-9664-7729-ee482397d981";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAACXbCU98TWqCN0u3tsAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgMRIL2fOnQAL4HoThT/PNgFz6jsALiJg2TJ5IX10tq8wAEKwBcQMRvrqqSMjwYy
    brXN4+VIyhOmT6YzrjpxHIF+BOOtl6Av9ojlJyhCjGdl6p/XFXdASuRvjaM+2SHuQOhRsj3r4QI1HEg
    oaP1ehVnuRRONQP/bWfI0qk/QZeJ/b93CRuBv3alqrGaKiAtU0qRf8YiYMjn3Ec/zc8AE4ACAALAAAE
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAg/leG+hSsL2gBiUXHSSzj3HI0jkk
    Dbh7UxWJgx2Cef+z/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAACz9FgLGumnFkuMlo
    E2VTbZm4PVL+BP4igOrLoGDHWfT0axkAoRbSeddGccm6D3GrnFHSdpYkRwLjSO8tfa52y92xYIEXumk
    +LyXVCc6qHywCM0Suw=
  '';

  system.stateVersion = "25.05";
}
