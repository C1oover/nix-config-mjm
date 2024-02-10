{
  imports = [
    ./blackbox-dns-ad-blocking.nix
    ./blackbox-dns-private.nix
    ./blackbox-dns-public.nix
    ./consul-agent.nix
    ./consul-connect-envoy.nix
    ./consul-exporter.nix
    ./consul-services.nix
    ./homelab-https.nix
    ./nomad-agent.nix
    ./proxmox.nix
    ./pushgateway.nix
    ./vault.nix
  ];
}
