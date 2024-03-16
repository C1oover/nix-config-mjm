{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/ingress
    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "brontes";

  boot.initrd.systemd.enableTpm2 = false;

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
    ip = "100.113.14.91";
  };

  vault-secrets.roleId = "3c25aad2-394f-9d07-2885-ebe80f05e9db";

  system.stateVersion = "21.03";
}
