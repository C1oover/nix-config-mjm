{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${inputs.hardware}/framework/13-inch/13th-gen-intel"
    ./hardware-configuration.nix
    ./mounts.nix
    ./secrets.nix
  ];

  deployment.targetHost = null;

  mjm.desktop.enable = true;
  mjm.secureboot.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "32G";
    };
    directories = [ "/home" ];
  };

  # boot.kernelPackages = pkgs.linuxPackagesFor (
  #   pkgs.linux_testing.override {
  #     argsOverride = {
  #       modDirVersion = "6.8.0-rc1";
  #       src = pkgs.fetchgit {
  #         url = "https://evilpiepirate.org/git/bcachefs.git";
  #         rev = "9cde7c92bce99069531cccdd6cd3412f3242a289";
  #         hash = "sha256-Jgg0WXIvGJLMJjXIMRKszVw/g+rXK7q9uVx7lNt30wE=";
  #       };
  #     };
  #   }
  # );

  environment.systemPackages = [
    pkgs.unofficial-homestuck-collection
    config.boot.kernelPackages.perf
  ];

  boot.initrd.systemd.services."bcachefs-unlock@" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecCondition = "";
  };

  networking.hostName = "persephone";

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
