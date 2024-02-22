{
  services.lldap = {
    enable = true;
    settings = {
      http_url = "https://ldap.home.mattmoriarity.com";
      ldap_base_dn = "dc=home,dc=mattmoriarity,dc=com";
      database_url = "postgres://lldap@%2Frun%2Fpostgresql:5432/lldap";
    };
  };

  systemd.services.lldap.after = [ "postgresql.service" ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "lldap" ];
    ensureUsers = [
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    3890
    17170
  ];

  services.consul.services.lldap = {
    port = 17170;

    checks = [
      {
        name = "lldap HTTP API";
        http = "http://localhost:17170/health";
        interval = "30s";
        timeout = "5s";
      }
    ];
  };
}
