{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default

    ../common/global/nixos
    ../common/users/matt
  ];

  networking.hostName = "uranus";

  wsl = {
    enable = true;
    nativeSystemd = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "matt";
    startMenuLaunchers = true;
  };

  nixpkgs.overlays = [inputs.jujutsu.overlays.default];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "23.05";
}
