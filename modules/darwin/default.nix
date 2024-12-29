{
  imports = [
    ../common/nushell.nix
    ../common/base

    ./consul.nix
    ./consul-services.nix
    ./server
    ./ssh.nix
  ];
}
