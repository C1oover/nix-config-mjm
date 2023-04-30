{
  imports = [
    ../common/global/darwin.nix
    ../common/users/matt

    ../common/optional/yabai.nix
  ];

  networking.computerName = "Mars";
  networking.hostName = "mars";
}
