{ inputs, ... }:
{
  imports = [
    "${inputs.catppuccin}/modules/home-manager"

    ./aerospace
    ./base.nix
    ./desktop
    ./dock.nix
    ./emacs.nix
    ./email.nix
    ./firefox
    ./git
    ./helix
    ./homelab
    ./shell
    ./syncthing.nix
    ./terminal
    ./work
  ];
}
