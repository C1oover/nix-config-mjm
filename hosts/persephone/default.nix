{
  pkgs,
  lib,
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
    directories = [
      "/home"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
      "/etc/NetworkManager/system-connections"
    ];
  };

  preservation.preserveAt."/persist".users.matt.directories = lib.mkForce [ ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

  boot.swraid.enable = false;

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  networking.hostName = "persephone";
  networking.networkmanager.enable = true;

  # sddm will silently wait 30 sec for a fingerprint after login before timing out
  # i don't want to login with fingerprint anyway (since it wouldn't unlock kwallet)
  security.pam.services.login.fprintAuth = false;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
