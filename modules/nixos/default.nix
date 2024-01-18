{
  consul-services = import ./consul-services.nix;
  netbox = import ./netbox.nix;
  vault-agent = import ./vault-agent.nix;
}
