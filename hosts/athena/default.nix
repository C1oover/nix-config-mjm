{
  imports = [ ../common/users/matt ];

  networking.computerName = "Athena";
  networking.hostName = "athena";

  mjm.desktop.enable = true;

  homebrew.casks = [
    "cleanshot"
    "loom"
    "nikitabobko/tap/aerospace"
    "notunes"
    "orbstack"
    "postico"
    "slab"
    "teleport-connect"
  ];

  homebrew.brews = [
    # openssl is needed for building erlang with asdf
    "openssl@1.1"
    "openssl@3"
  ];

  system.stateVersion = 4;
  nixpkgs.system = "aarch64-darwin";
}
