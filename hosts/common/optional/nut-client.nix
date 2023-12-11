{config, ...}: {
  power.ups = {
    enable = true;
    mode = "netclient";
    upsmon.monitor.tripplite = {
      system = "tripplite@10.0.0.2";
      user = "upsmon_secondary";
      type = "secondary";
      passwordFile = config.age.secrets."nut-secondary-password".path;
    };
  };

  age.secrets."nut-secondary-password".file = ../../../secrets/nut-secondary-password.age;
}
