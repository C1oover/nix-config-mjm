{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixvim

    ./services/nginx.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking.hostName = "nyx";
  networking.domain = "mattmoriarity.com";

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    ''ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGUN/c2PaYqQKsu0lgO6O8aeHZA4iT3OopYjyMs+IKokbZZTaHuMibstCYsUyztv8KacbDQ9oqnPu54rDgoZ+jw= YubiKey #16946830 PIV Slot 9a''
  ];

  nix.settings = {
    experimental-features = ["flakes" "nix-command"];
  };
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
  };

  environment.systemPackages = with pkgs; [git];
}
