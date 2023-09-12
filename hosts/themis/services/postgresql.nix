{
  pkgs,
  config,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    authentication = ''
      # "local" is for Unix domain socket connections only
      local   all             all                                     trust
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            trust
      # IPv6 local connections:
      host    all             all             ::1/128                 trust

      # allow connections from the local network
      host	all		consul		10.0.2.10/32		trust
      host	all		all		10.0.0.0/8		scram-sha-256
    '';
    ensureDatabases = [
      "atuin"
    ];
    ensureUsers = [
      {
        name = "atuin";
        # the atuin user also needs to be the owner of the atuin DB, which isn't possible
        # to set up from this module.
        ensurePermissions = {
          "DATABASE atuin" = "ALL PRIVILEGES";
        };
        ensureClauses = {
          login = false;
        };
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [config.services.postgresql.port];

  services.consul.services.postgresql = {
    inherit (config.services.postgresql) port;

    checks = [
      {
        name = "postgresql TCP check";
        tcp = "localhost:5432";
        interval = "15s";
        timeout = "5s";
      }
    ];
  };
}
