{config, ...}: {
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;
    ups.tripplite = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        ''vendorid = "09ae"''
        ''productid = "3024"''
      ];
    };
    users = {
      upsmon = {
        upsmon = "primary";
        passwordFile = config.age.secrets."nut-primary-password".path;
      };
      upsmon_secondary = {
        upsmon = "secondary";
        passwordFile = config.age.secrets."nut-secondary-password".path;
      };
    };
    upsd = {
      listen = [{address = "10.0.0.2";}];
    };
    upsmon.monitor.tripplite = {
      system = "tripplite@10.0.0.2";
      user = "upsmon";
      type = "primary";
    };
  };

  age.secrets = {
    "nut-primary-password".file = ../../../secrets/nut-primary-password.age;
    "nut-secondary-password".file = ../../../secrets/nut-secondary-password.age;
  };
}
