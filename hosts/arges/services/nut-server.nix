{config, ...}: {
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

  environment.etc."nut/upsd.conf".text = ''
    LISTEN 10.0.0.2
  '';

  environment.etc."nut/upsmon.conf".source = config.age.secrets."upsmon.conf".path;
  environment.etc."nut/upsd.users".source = config.age.secrets."upsd.users".path;

  systemd.tmpfiles.rules = ["d /var/lib/nut 0700 root wheel - -"];

  networking.firewall.allowedTCPPorts = [3493];

  age.secrets = {
    "upsmon.conf".file = ../../../secrets/nut-server-upsmon-conf.age;
    "upsd.users".file = ../../../secrets/nut-server-upsd-users.age;
  };
}
