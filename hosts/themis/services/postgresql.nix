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
      host	all		all		10.0.0.0/8		scram-sha-256
      host  all   all   2601:282:167f:3eec::/64  scram-sha-256
    '';
    ensureDatabases = [
      "attic"
      "atuin"
      "authelia"
      "authelia_external"
      "grafana"
      "homelab"
      "linkding"
      "lldap"
      "miniflux"
      "netbox"
      "paperless"
    ];
    ensureUsers = [
      {
        name = "atuin";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "attic";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "authelia";
        ensureDBOwnership = true;
        # this user should also be made owner of the authelia_external db, but
        # this module can't do that
        ensureClauses.login = false;
      }
      {
        name = "grafana";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "homelab";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "linkding";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "lldap";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "miniflux";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "netbox";
        ensureDBOwnership = true;
        ensureClauses.login = false;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
        ensureClauses.login = false;
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
