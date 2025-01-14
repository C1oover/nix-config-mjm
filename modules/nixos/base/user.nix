{ config, pkgs, ... }:
let
  username = config.mjm.username;
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = "MJ";
    extraGroups = [ "wheel" ];
    shell = pkgs.nushell;
    hashedPassword = "$y$j9T$tM/RKSjlb5ljgtpGT/Y8N1$3oXxWQh/q.KKCcJKoyVeIUVqjjt76EWX.uNEJRASt04";
  };
}
