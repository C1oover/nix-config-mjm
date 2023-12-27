{inputs, ...}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # TODO remove later
  boot.initrd.preFailCommands = "allowShell=1";

  age.identityPaths = ["/nix/persist/etc/ssh/ssh_host_ed25519_key"];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/jellyfin"
      {
        directory = "/var/lib/sabnzbd";
        user = "sabnzbd";
        group = "sabnzbd";
      }
      {
        directory = "/var/lib/sonarr/.config/NzbDrone";
        user = "sonarr";
        group = "sonarr";
      }
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
