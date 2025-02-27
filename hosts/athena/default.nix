{
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

    # TODO switch this to install via nix once nixpkgs has 0.16+
    "asdf"
  ];

  # networking.hosts =
  #   let
  #     slabDomains = [
  #       "matt.slabdev.com"
  #       "slabdev.com"
  #       "api.slabdev.com"
  #       "cdn.slabdev.com"
  #     ];
  #   in
  #   {
  #     "127.0.0.1" = slabDomains;
  #     "::1" = slabDomains;
  #   };

  system.stateVersion = 4;
  nixpkgs.system = "aarch64-darwin";
}
