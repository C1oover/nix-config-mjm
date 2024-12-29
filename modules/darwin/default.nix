{ inputs, ... }:
{
  imports = [
    "${inputs.home-manager}/nix-darwin"

    ../common/nushell.nix

    ../../services/darwin.nix

    ./base
    ./consul.nix
    ./consul-services.nix
    ./server
    ./ssh.nix
  ];
}
