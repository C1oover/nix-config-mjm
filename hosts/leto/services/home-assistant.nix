{config, ...}: {
  # ugh
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"

      "apple_tv"
      "jellyfin"
      "homekit"
      "homekit_controller"
      "hue"
      "icloud"
      "roku"
      "unifi"
    ];
    config = {
      default_config = {};
      homeassistant = {
        unit_system = "imperial"; # i'm sorry
        latitude = "!secret latitude_home";
        longitude = "!secret longitude_home";
        country = "US";
        currency = "USD";
        time_zone = "America/Denver";
        external_url = "https://home.midna.dev";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "10.0.0.3"
          "10.0.0.4"
          "2601:282:167f:3eec:dea6:32ff:fed5:d840"
          "2601:282:167f:3eec:dea6:32ff:fe96:bc05"
        ];
      };
      automation = "!include automations.yaml";
      scene = "!include scenes.yaml";
    };
  };

  services.consul.services.home-assistant = {
    port = config.services.home-assistant.config.http.server_port;
  };
}
