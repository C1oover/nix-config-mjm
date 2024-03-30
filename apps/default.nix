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
    "matrix-server"
    "media-server"
    "netbox"
    "otel-collector"
    "postgresql"
    "prometheus"
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
    ./ingress
    ./linkding
    ./miniflux
    ./nut
    ./paperless
    ./proxmox
    ./taskserver
    ./vault
  ] ++ map (s: ../services/${s}/service.nix) services;
}
