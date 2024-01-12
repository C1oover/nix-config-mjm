{inputs, ...}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

  environment.persistence."/persist" = {
    directories = [
      "/nix"
      "/var/lib/docker/volumes"
      "/var/lib/private/lldap"
      {
        directory = "/var/lib/netbox";
        user = "netbox";
        group = "netbox";
      }
      {
        directory = "/var/lib/paperless";
        user = "paperless";
        group = "paperless";
      }
      {
        directory = "/var/lib/prometheus2";
        user = "prometheus";
        group = "prometheus";
      }
      {
        directory = "/var/lib/hass";
        user = "hass";
        group = "hass";
      }
      {
        directory = "/var/lib/taskserver";
        user = "taskd";
        group = "taskd";
      }
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
