{
  nix.gc = {
    automatic = true;
    randomizedDelaySec = "30min";
    options = "--delete-older-than 3d";
  };

  nix.settings = {
    min-free = 100 * 1024 * 1024;
    max-free = 2 * 1024 * 1024 * 1024;
  };
}
