{config, ...}: {
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    environmentFile = config.age.secrets."wpa-supplicant.env".path;

    networks = {
      "Shrimp Heaven Now" = {
        psk = "@PSK_SHN@";
      };
    };
  };

  age.secrets."wpa-supplicant.env".file = ../../../secrets/wpa-supplicant-env.age;
}
