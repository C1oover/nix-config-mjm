let
  services = [
    "actual"
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
    "nut"
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

    ./backup
    ./gitlab
    ./proxmox
  ] ++ map (s: ../services/${s}/service.nix) services;
}
