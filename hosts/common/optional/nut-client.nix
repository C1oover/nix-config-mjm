{config, ...}: {
  power.ups = {
    enable = true;
    mode = "netclient";
  };

  # don't need these in netclient mode but the module isn't smart enough to disable them.
  systemd.services.upsd.enable = false;
  systemd.services.upsdrv.enable = false;

  environment.etc."nut/upsmon.conf".source = config.age.secrets."upsmon.conf".path;

  age.secrets."upsmon.conf".file = ../../../secrets/nut-client-upsmon-conf.age;
}
