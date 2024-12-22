{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
in
{
  users.users.mjm = mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      isNormalUser = true;
      description = "MJ";
      extraGroups = [ "wheel" ];
      shell = config.programs.nushell.wrappedPackage;
      hashedPassword = "$y$j9T$tM/RKSjlb5ljgtpGT/Y8N1$3oXxWQh/q.KKCcJKoyVeIUVqjjt76EWX.uNEJRASt04";
    })
    (mkIf pkgs.stdenv.isDarwin {
      home = "/Users/mjm";
    })
  ];

  home-manager.users.mjm = ../../../../home/matt/${config.networking.hostName}.nix;
}
