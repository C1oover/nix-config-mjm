{
  imports = [ ./common.nix ];

  services.consul.extraConfig.bind_addr = "0.0.0.0";
}
