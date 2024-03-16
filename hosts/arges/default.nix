{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/raspberry-pi.nix
  ];

  networking.hostName = "arges";

  boot.initrd.systemd.enableTpm2 = false;

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
