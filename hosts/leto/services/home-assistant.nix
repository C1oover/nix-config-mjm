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
    ];
    config = {
      homeassistant = {
        unit_system = "imperial"; # i'm sorry
        # extremely approximate, you can't trick me into doxxing myself home assistant
        latitude = "39.75";
        longitude = "-105";
        country = "US";
        currency = "USD";
        external_url = "https://home.midna.dev";
      };
      default_config = {};
    };
  };

  services.consul.services.home-assistant = {
    port = config.services.home-assistant.config.http.server_port;
  };
}
