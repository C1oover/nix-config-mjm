{
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_ADDRESS = "::";
      ROCKET_PORT = 8222;
      DOMAIN = "https://pass.midna.dev";
    };
  };

  networking.firewall.allowedTCPPorts = [8222];

  services.consul.services.vaultwarden = {
    port = 8222;

    checks = [
      {
        name = "vaultwarden is alive";
        http = "http://localhost:8222/alive";
        interval = "15s";
        timeout = "10s";
      }
    ];
  };
}
