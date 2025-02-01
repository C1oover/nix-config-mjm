{
  imports = [
    ../common/nushell.nix

    ../../services/darwin.nix

    ./base
    ./consul-services.nix
    ./desktop
    ./server
    ./ssh.nix
  ];
}
