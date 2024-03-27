let
  services = [
    "authelia"
    "garage"
    "gitlab-runner"
    "media-server"
  ];
in
{
  imports = [
    ../modules/apps

    ./actual
    ./attic
    ./atuin
    ./backup
    ./consul
    ./chat
    ./gitlab
    ./grafana
    ./homelab/app.nix
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
    ./prometheus
    ./proxmox
    ./taskserver
    ./vault
    ./vaultwarden
  ] ++ map (s: ../services/${s}/service.nix) services;
}
