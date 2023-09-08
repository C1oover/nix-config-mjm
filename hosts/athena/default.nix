{
  imports = [
    ../common/global/darwin
    ../common/users/matt
  ];

  networking.computerName = "Athena";
  networking.hostName = "athena";

  x.nixvim.enableIde = true;

  homebrew.casks = [
    "cleanshot"
    "loom"
    "postico"
    "slab"
  ];

  # openssl is needed for building erlang with asdf
  homebrew.brews = [
    "openssl@1.1"
    "openssl@3"
  ];
}
