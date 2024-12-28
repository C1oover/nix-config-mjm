{ localModulesPath, ... }:
{
  imports = [ "${localModulesPath}/nixos/profiles/proxmox-vm.nix" ];

  networking.hostName = "megaera";

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
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAAA8R2MzwziBLsk8GL0AAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAg3kVlC2p0xdxvKrRaeFkdpRlHEcd/fDLWShQC7/FzsdkAEPXBOueAzng1w3Aqgz
        Jzo/zPr3UxhQtzMUi6FTyB2Tcm0i68BaBARQxXQtc2DYfVVfItV7DkOt77OO/f84/zJ/spyWSeqfVAl
        a9ZTWbWEOE29oGELR76XiQMzOUXe+GBlgnC3ltO3ERM4Iy2S4lnoPqlWLY++9bMds9YAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgV1NN3k6dEL50/tyrw3wvIyJB5/2
        QJloju/NdTOyeKrH/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAABImhgCWrqTi16c1
        6YUteoxr6uXSSXYu0sSg7L1EMiJpXPqyE9ySYOtqH05LjzSkrF+ULz1IiqEI+Kylt1OfRPnKX+U+Z1O
        J5mXDPx22bLMcET5fjWIJwfHl/6Te0=
      ''
      ''
        DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAACDlNep9gKK0tc2l4MAAAAAgAAAAAAAAAALACM
        A8AAAACAAAAAAngAg32VzbSSpftq1ygAVE9yVA0e/My9lCfdsEiIJkPYqeTsAEHwOM8dKUrvZEx+of/
        j3sEfzQKLPeC804Syq18qxVkax12E8kEz42tHs5ij5zhgnBMWIIMtSa6J849uu7VGgvoMm3In4wXXk1
        uS4dWHOnctDdrQCnGSNC3RI/uYa0d2+VECFwryrzoCsl/hfGTScjacy0BSGwBRXQkRCAE4ACAALAAAA
        EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgvU/oeNslGV0obUY13KK5DkDcZ7R
        jnqg+kivviF5MF+v/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAABJI8pvH56icAXogA
        URLrELDOhujn6NE5wnN3zoHPDCiHEaYmvyrbYOHRdG/WL12JKAKGjMATqM+LVziXv3g/Btv9mgcl9eq
        ncOcntDSUAsObnupHcrKSZJVKGe+t8=
      ''
    ];
  };

  vault-secrets.roleId = "585e9436-2eae-a837-0beb-174f1c289fff";
  vault-secrets.encryptedSecretId = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAADZqkPMDyUAD/sSIyMAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgZ9AIYKBAl36gp6mOR/lKWOxnrHEFN4kT4aVr2bMY3WgAEP7XTlhCz9EO6uWmWo
    ZuShto+JZBCnO7dyOMDRRTwf6xDUYVB+dX1cOEUXZoNS73UgaTu314Xk6tXfhfsqWP1kH7vhTew71EN
    LDBXVTVGuvzwRTLMOhDLEfk7yAZMYUoJUjvbJviHdCnaVC7mfcbnSthlkrAsrZFbvO5AE4ACAALAAAA
    EgAg/928wzzwZljax6QULbex0pLe130yDZJRVcq/rrtdgRsAEAAgBFRTTT0PwQ1AYh1gm46tguCqsKW
    d3k/TMSnOJ9l2YhL/3bzDPPBmWNrHpBQtt7HSkt7XfTINklFVyr+uu12BGwAAAAA+9/tLLZM/0Upuon
    FRxeBTI5cOOE0ia86hIhY4LnmUQqL934s5X5aOarL5kP3Mz6dzZPEaA1kdOToG25ImiuH4qfLseIzDC
    ELk++4W2C3o1kB+W5Fs
  '';

  system.stateVersion = "22.11";
}
