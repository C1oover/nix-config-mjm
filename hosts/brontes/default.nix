{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/ingress
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
  mjm.tailscale = {
    enable = true;
    ip = "100.113.14.91";
  };

  vault-secrets.roleId = "3c25aad2-394f-9d07-2885-ebe80f05e9db";

  system.stateVersion = "21.03";
}
