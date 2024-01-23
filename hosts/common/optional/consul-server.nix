{
  imports = [ ./consul-agent.nix ];

  services.consul = {
    webUi = true;

    extraConfig = {
      server = true;
      bootstrap_expect = 3;

      telemetry = {
        prometheus_retention_time = "1h";
        disable_hostname = true;
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ 8302 ];
}
