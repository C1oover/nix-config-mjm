{config, ...}: {
  services.redis.servers."" = {
    enable = true;
    openFirewall = true;
    bind = null;

    settings = {
      protected-mode = false;
    };
  };

  services.consul.services.redis = {
    inherit (config.services.redis.servers."") port;
  };
}
