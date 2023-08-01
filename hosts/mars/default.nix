{
  imports = [
    ../common/global/darwin
    ../common/users/matt

    ../common/optional/yabai.nix
  ];

  networking.computerName = "Mars";
  networking.hostName = "mars";

  x.nixvim.enableIde = true;
}
