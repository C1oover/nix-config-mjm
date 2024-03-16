{ pkgs, config, ... }:
{
  mjm.state.directories = [
    {
      directory = config.services.jellyfin.dataDir;
      inherit (config.services.jellyfin) user group;
    }
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [ cifs-utils ];

  systemd.tmpfiles.settings."10-videos"."/videos".d = { };

  users.groups.media = { };
  users.users.jellyfin.extraGroups = [ "media" ];

  fileSystems."/videos" = {
    device = "//selene.home.mattmoriarity.com/media";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=120"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "credentials=${config.vault-secrets.templates.smb-creds.path}"
      "gid=media"
      "forcegid"
      "file_mode=0664"
      "dir_mode=0775"
      "nounix"
      "nobrl"
    ];
  };

  vault-secrets.wantedBy = [ "videos.mount" ];
  vault-secrets.templates.smb-creds.text = ''
    username=mediaserver
    password={{ with secret "kv/mediaserver" }}{{ .Data.data.smb_password }}{{ end }}
  '';

  services.consul.services.jellyfin = {
    port = 8096;

    checks = [
      {
        name = "jellyfin is ready";
        http = "http://localhost:8096/health";
        interval = "15s";
        timeout = "10s";
        failures_before_warning = 2;
        failures_before_critical = 6;
      }
    ];
  };
}
