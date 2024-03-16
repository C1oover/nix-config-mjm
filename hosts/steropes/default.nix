{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/ingress
    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "steropes";

  mjm.consul-agent.enable = true;
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
    ip = "100.103.187.51";
  };

  vault-secrets.roleId = "61445b18-4ebe-027e-7bb9-2c4f6711d408";

  boot.initrd.systemd.enableTpm2 = false;

  system.stateVersion = "21.03";
}
