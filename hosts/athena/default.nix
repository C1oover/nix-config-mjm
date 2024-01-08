{inputs, ...}: {
  imports = [
    ../common/global/darwin
    ../common/users/matt
  ];

  networking.computerName = "Athena";
  networking.hostName = "athena";

  homebrew.casks = [
    "cleanshot"
    "loom"
    "postico"
    "rectangle-pro"
    "slab"
    "teleport-connect"
  ];

  # openssl is needed for building erlang with asdf
  homebrew.brews = [
    "openssl@1.1"
    "openssl@3"
  ];

  nixpkgs.overlays = [inputs.jujutsu.overlays.default];
}
