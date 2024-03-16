{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/jellyfin"
      "/var/lib/private/garage/meta"
      "/var/lib/private/invidious"
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "0750";
      }
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
      {
        directory = "/var/lib/radarr/.config/Radarr";
        user = "radarr";
        group = "radarr";
      }
      {
        directory = "/var/lib/readarr";
        user = "readarr";
        group = "readarr";
      }
      {
        directory = "/var/lib/readarr-audio";
        user = "readarr";
        group = "readarr";
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
      directories = [ ".local/share/atuin" ];
    };
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
