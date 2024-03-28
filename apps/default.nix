let
  services = [
    "atticd"
    "authelia"
    "consul"
    "garage"
    "gitlab-runner"
    "homelab"
    "matrix-server"
    "media-server"
    "netbox"
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
    ./home-assistant
    ./ingress
    ./linkding
    ./loki
    ./miniflux
    ./nut
    ./otel
    ./paperless
    ./proxmox
    ./taskserver
    ./vault
    ./vaultwarden
  ] ++ map (s: ../services/${s}/service.nix) services;
}
