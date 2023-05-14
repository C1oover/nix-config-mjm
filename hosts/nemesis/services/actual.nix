{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  virtualisation.oci-containers.container.actual = {
    # actual budget 23.5.0
    image = "ghcr.io/actualbudget/actual-server@sha256:68387ec93bbe052feb2c2f9f728d6ea4f4bf697008ef02cc0263ec93a07625fd";
    volumes = [ "actual_data:/data" ];
    ports = [ "5006:5006" ];
  };

  services.consul.extraConfigFiles = [
    (toString (format.generate "actual.json" {
      service = {
        name = "actual";
        id = "actual:${config.networking.hostName}";
        port = 5006;
      };
    }))
  ];
}
