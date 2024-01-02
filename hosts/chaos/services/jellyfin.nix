{
  pkgs,
  config,
  ...
}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [cifs-utils];

  systemd.tmpfiles.rules = ["d /videos"];

  users.groups.media = {};

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
      "gid=media"
      "forcegid"
      "file_mode=0664"
      "dir_mode=0775"
      "noperm"
      "nounix"
      "nobrl"
    ];
  };

  age.secrets."smb-creds".file = ../../../secrets/smb-creds-server.age;

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
