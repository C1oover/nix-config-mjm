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

  swapDevices = [
    {
      device = "/persist/swap";
      size = 20 * 1024;
    }
  ];

  mjm.consul-agent.enable = true;
  mjm.gitlab-runner.enable = true;
  mjm.nut = {
    enable = true;
    mode = "server";
  };
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
    ip = "100.89.174.9";
  };

  vault-secrets.roleId = "841fdaf1-6a2d-f471-ad85-ae485c232b89";

  system.stateVersion = "21.03";
}
