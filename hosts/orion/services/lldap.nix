{
  config,
  pkgs,
  ...
}: let
  format = pkgs.formats.json {};
in {
  virtualisation.oci-containers.containers = {
    lldap = {
      image = "nitnelave/lldap:stable";
      volumes = ["lldap_data:/data"];
      ports = [
        "3890:3890" # ldap
        "17170:17170" # web interface
      ];
      environment = {
        LLDAP_LDAP_BASE_DN = "dc=home,dc=mattmoriarity,dc=com";
      };
    };
  };

  services.consul.extraConfigFiles = [
    (toString (format.generate "lldap.json" {
      service = {
        name = "lldap";
        id = "lldap:${config.networking.hostName}";
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
    }))
  ];
}
