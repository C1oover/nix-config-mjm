let
  services = [
    "atticd"
    "atuin"
    "authelia"
    "consul"
    "garage"
    "gitlab-runner"
    "grafana"
    "home-assistant"
    "homelab"
    "ingress"
    "linkding"
    "matrix-server"
    "media-server"
    "miniflux"
    "netbox"
    "otel-collector"
    "paperless"
    "postgresql"
    "prometheus"
    "taskserver"
    "vault"
    "vaultwarden"
  ];
in
{
  imports = [
    ../modules/apps

    ./actual
    ./backup
    ./gitlab
    ./nut
    ./proxmox
  ] ++ map (s: ../services/${s}/service.nix) services;
}
