{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  environment.persistence."/nix/persist" = {
    directories = [ "/var/lib/private/garage/meta" ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    users.matt = {
      directories = [ ".local/share/atuin" ];
    };
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
