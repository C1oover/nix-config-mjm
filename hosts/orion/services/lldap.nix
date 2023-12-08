{
  pkgs,
  inputs,
  ...
}: {
  services.lldap = {
    enable = true;
    # hold back to an old commit that actually builds
    package = inputs.nixos-lldap.legacyPackages.${pkgs.system}.lldap;
    settings = {
      http_host = "0.0.0.0";
      ldap_host = "0.0.0.0";
      http_url = "https://ldap.home.mattmoriarity.com";
      ldap_base_dn = "dc=home,dc=mattmoriarity,dc=com";
    };
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
