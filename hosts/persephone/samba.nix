{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [ cifs-utils ];

  systemd.tmpfiles.settings."10-videos"."/videos".d = { };

  fileSystems."/videos" = {
    device = "//selene.home.mattmoriarity.com/media";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=120"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "credentials=${config.age.secrets."smb-creds".path}"
      "uid=1000"
      "gid=1000"
    ];
  };

  age.secrets."smb-creds".file = ../../secrets/smb-creds.age;
}
