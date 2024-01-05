{inputs, ...}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # TODO remove later
  boot.initrd.preFailCommands = "allowShell=1";

  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

  environment.persistence."/persist" = {
    directories = [
      "/nix"
      "/boot"
      "/var/lib/acme"
      # TODO remove this later by setting up nix config to join tailscale automatically
      "/var/lib/tailscale"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    users.matt = {
      directories = [
        ".local/share/atuin"
      ];
    };
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
