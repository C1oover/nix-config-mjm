{ inputs, ... }:
{
  imports = [
    "${inputs.catppuccin}/modules/home-manager"

    ./base.nix
    ./dock.nix

    # TODO move these to this directory
    ../../home/matt/features/aerospace
    ../../home/matt/features/desktop
    ../../home/matt/features/emacs
    ../../home/matt/features/email
    ../../home/matt/features/firefox
    ../../home/matt/features/git
    ../../home/matt/features/helix
    ../../home/matt/features/homelab
    ../../home/matt/features/shell
    ../../home/matt/features/syncthing
    ../../home/matt/features/terminal
    ../../home/matt/features/work
  ];
}
