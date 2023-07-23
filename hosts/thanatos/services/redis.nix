{config, ...}: {
  services.redis.servers."" = {
    enable = true;
    openFirewall = true;
    bind = null;
  };

  services.consul.services.redis = {
    inherit (config.services.redis.servers."") port;
  };
}
