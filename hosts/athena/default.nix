{
  imports = [
    ../common/global/darwin
    ../common/users/matt
  ];

  networking.computerName = "Athena";
  networking.hostName = "athena";

  homebrew.casks = [
    "cleanshot"
    "loom"
    "nikitabobko/tap/aerospace"
    "notunes"
    "postico"
    "rectangle-pro"
    "slab"
    "teleport-connect"
  ];

  homebrew.brews = [
    # openssl is needed for building erlang with asdf
    "openssl@1.1"
    "openssl@3"
  ];
}
