let
  services = [
    "authelia"
    "garage"
    "gitlab-runner"
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
    ./mediaserver
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
