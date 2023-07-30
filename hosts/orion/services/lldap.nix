{
  # I suspect issues with podman's ability to clean up external containers
  virtualisation.oci-containers.backend = "docker";

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
