{
  imports = [
    ./consul-agent.nix
    ./consul-connect-envoy.nix
    ./consul-services.nix
    ./nomad-agent.nix
    ./pushgateway.nix
    ./vault.nix
  ];
}
