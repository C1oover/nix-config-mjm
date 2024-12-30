{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge optional;
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

  home-manager.users.mjm.imports =
    let
      machineSpecificConfig = ../../../../home/matt/${config.networking.hostName}.nix;
    in
    [
      ../../../../home/matt/global
    ]
    ++ optional (builtins.pathExists machineSpecificConfig) machineSpecificConfig;

}
