{inputs, ...}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home"
      "/nix"
      "/var/log"
      "/var/lib/libvirt"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
