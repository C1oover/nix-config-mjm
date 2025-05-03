{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    elem
    flatten
    flip
    genAttrs
    mapAttrs'
    length
    mkIf
    mkOption
    optionalAttrs
    pipe
    removeAttrs
    types
    ;
  cfg = config.mjm.garage;

  clients =
    if config.mjm.minimal.enable then
      (
        let
          names = attrNames cfg.clients;
          clientCount = length names;
        in
        if clientCount > 2 then
          builtins.throw "too many garage clients in a microvm"
        else if clientCount == 2 && elem "backups" names then
          # in this case, the other client is expected to have write access
          # to the restic-backups bucket
          removeAttrs cfg.clients [ "backups" ]
        else
          cfg.clients
      )
    else
      cfg.clients;

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
              type = types.nullOr types.str;
              default = if config.mjm.minimal.enable then null else name;
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
          listen.early = true;
          target.service = "spiffe-garage";
          target.port = 3899;
        };
      }) clients
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
      }) clients;

    systemd.services =
      flip genAttrs (_: {
        environment.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI = "/creds";
      }) allServices
      // optionalAttrs config.mjm.minimal.enable {
        "s3-creds-ip" = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          before = map (name: "${name}-s3-creds-tunnel.socket") (attrNames clients);

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.iproute2}/bin/ip addr add 169.254.170.2/16 dev lo";
          };
        };
      };
  };
}
