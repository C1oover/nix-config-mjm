{pkgs, ...}: {
  power.ups = {
    enable = true;
    mode = "netserver";
    ups.tripplite = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        ''vendorid = "09ae"''
        ''productid = "3024"''
      ];
    };
  };

  environment.etc."nut/uspd.conf".text = ''
    LISTEN 10.0.0.2
  '';

  environment.etc."nut/upsmon.conf".text = ''
    MONITOR tripplite@localhost 1 upsmon password primary
    SHUTDOWNCMD ${pkgs.systemd}/bin/shutdown -h +0
  '';

  environment.etc."nut/upsd.users".text = ''
    [upsmon]
      password = password
      upsmon primary
  '';

  systemd.tmpfiles.rules = ["d /var/lib/nut 0700 root wheel - -"];
}
