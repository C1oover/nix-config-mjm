let
  services = [
    "atticd"
    "authelia"
    "garage"
    "gitlab-runner"
    "homelab"
    "media-server"
    "prometheus"
  ];
in
{
  imports = [
    ../modules/apps

    ./actual
    ./atuin
    ./backup
    ./consul
    ./chat
    ./gitlab
    ./grafana
    ./home-assistant
    ./ingress
    ./linkding
    ./loki
    ./miniflux
    ./netbox
    ./nut
    ./otel
    ./paperless
    ./postgresql
    ./proxmox
    ./taskserver
    ./vault
    ./vaultwarden
  ] ++ map (s: ../services/${s}/service.nix) services;
}
