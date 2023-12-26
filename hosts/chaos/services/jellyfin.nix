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

  fileSystems."/videos" = {
    device = "//selene.home.mattmoriarity.com/videos";
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
}
