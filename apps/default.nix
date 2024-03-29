let
  services = [
    "atticd"
    "authelia"
    "consul"
    "garage"
    "gitlab-runner"
    "home-assistant"
    "homelab"
    "matrix-server"
    "media-server"
    "netbox"
    "otel-collector"
    "postgresql"
    "prometheus"
  ];
in
{
  imports = [
    ../modules/apps

    ./actual
    ./atuin
    ./backup
    ./gitlab
    ./grafana
    ./ingress
    ./linkding
    ./loki
    ./miniflux
    ./nut
    ./paperless
    ./proxmox
    ./taskserver
    ./vault
    ./vaultwarden
  ] ++ map (s: ../services/${s}/service.nix) services;
}
