{ inputs, ... }:
{
  imports = [
    "${inputs.home-manager}/nix-darwin"

    ../common/nushell.nix

    ../../services/darwin.nix

    ./base
    ./consul-services.nix
    ./desktop
    ./server
    ./ssh.nix
  ];
}
