{config, ...}: {
  home-manager.users.matt = ../../../../home/matt/${config.networking.hostName}.nix;
}
