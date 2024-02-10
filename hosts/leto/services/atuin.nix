{ config, ... }:
{
  services.atuin = {
    enable = true;
    host = "::";
    openFirewall = true;
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "atuin";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "atuin" ];
  };

  services.consul.services.atuin =
    let
      inherit (config.services.atuin) port;
    in
    {
      inherit port;

      checks = [
        {
          name = "atuin is ready";
          http = "http://localhost:${toString port}/";
          interval = "15s";
          timeout = "5s";
        }
      ];
    };
}
