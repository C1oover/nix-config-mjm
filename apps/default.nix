let
  services = [
    "atticd"
    "authelia"
    "consul"
    "garage"
    "gitlab-runner"
    "grafana"
    "home-assistant"
    "homelab"
    "ingress"
    "matrix-server"
    "media-server"
    "netbox"
    "otel-collector"
    "paperless"
    "postgresql"
    "prometheus"
    "vault"
    "vaultwarden"
  ];
in
{
  imports = [
    ../modules/apps

    ./actual
    ./atuin
    ./backup
    ./gitlab
    ./linkding
    ./miniflux
    ./nut
    ./proxmox
    ./taskserver
  ] ++ map (s: ../services/${s}/service.nix) services;
}
