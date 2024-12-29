{
  imports = [
    ../common/nushell.nix

    ./consul.nix
    ./consul-services.nix
    ./server
    ./ssh.nix
  ];
}
