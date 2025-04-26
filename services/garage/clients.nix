{ lib, config, ... }:
let
  inherit (lib)
    attrValues
    flatten
    flip
    genAttrs
    mapAttrs'
    mkIf
    mkOption
    pipe
    types
    ;
  cfg = config.mjm.garage;

  allServices = pipe cfg.clients [
    attrValues
    (map (v: v.services))
    flatten
  ];
in
{
  options.mjm.garage.clients = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            namespace = mkOption {
              type = types.str;
              default = name;
            };
            services = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
          };
        }
      )
    );
  };

  config = mkIf (cfg.clients != { }) {
    mjm.spire.tunnels =
      mapAttrs' (name: c: {
        name = "${name}-s3-creds";
        value = {
          mode = "client";
          listen.address = "169.254.170.2:80";
          listen.namespace = c.namespace;
          target.service = "spiffe-garage";
          target.port = 3899;
        };
      }) cfg.clients
      // mapAttrs' (name: c: {
        name = "${name}-s3";
        value = {
          mode = "client";
          listen.port = 3902;
          listen.namespace = c.namespace;
          target.service = "s3.garage";
          target.port = 3902;
          # you're gonna think you can remove this, but then it will use s3.garage
          # which is fine for hostname checks but it's not the name in the spiffe id
          service = "garage";
        };
      }) cfg.clients;

    systemd.services = flip genAttrs (_: {
      environment.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI = "/creds";
    }) allServices;
  };
}
