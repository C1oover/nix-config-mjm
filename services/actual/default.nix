{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.actual;
in
{
  options.mjm.actual = {
    enable = mkEnableOption "actual";
  };

  config = mkIf cfg.enable {
    mjm.services.actual = { };
    mjm.state.directories = [ "/var/lib/docker/volumes" ];

    ingress.virtualHosts.budget = {
      upstream.service.name = "actual";
    };

    # I suspect issues with podman's ability to clean up external containers
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.actual = {
      # actual budget 23.7.2
      image = "ghcr.io/actualbudget/actual-server@sha256:fff7256ec79c860e44552965abd5a8a49dae1217e3cfa547e72c432d9edc4bee";
      volumes = [ "actual_data:/data" ];
      ports = [ "5006:5006" ];
    };

    services.consul.services.actual = {
      port = 5006;
    };
  };
}
