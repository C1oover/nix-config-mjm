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
  ];

  deployment.targetHost = null;

  mjm.desktop.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    directories = [
      "/home"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
      "/etc/NetworkManager/system-connections"
      "/etc/secureboot"
    ];
  };

  preservation.preserveAt."/persist".users.matt.directories = lib.mkForce [ ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
    pkgs.sbctl
    config.boot.kernelPackages.perf
  ];

  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd.systemd.contents."/etc/credstore.encrypted/bcachefs-sysroot-persist.mount".text = ''
    DHzAexF2RZGcSwvqCLwg/iAAAAABAAAADAAAABAAAADeKOPpfopRrmyft1oAAAAAgAAAAAAAAAALACM
    A8AAAACAAAAAAngAgd8Rwo7dlii5r64edJdjGHiVFfDn6FaaQCkh4WooBdxYAEI/+gJ8+cDbcuibjM7
    edJfm67CRhyQrN7SJhvryYnekP0NiyOnyYcup8ZegedwyVjPqGsBKLdMNIlN4r0IhRioAzl/12DtTRH
    W6FkDd8BoCG7k+lUoEbpUtVJfb4L728J3iw/GV+oqkYXJuPQ2Fcj5paMy+4SRi5LVjiAE4ACAALAAAE
    EgAg+1290dntdlxvKWYpUns6QT/OVwfYkkEDV6lleVTWlKkAEAAglJMt0RNCJpUkWFs7G4Z8ob2/488
    5BSkly667p8fLdKb7Xb3R2e12XG8pZilSezpBP85XB9iSQQNXqWV5VNaUqQAAAACXxBiQiqAfKycEKM
    1aR3MGeXdUopZYMq/O7UD1QweqeNePHO4CiaB9Uwdn1+ey8xUUCmFnwHHal5sgDryt/BfB2fna8K0YS
    BC5qn4eyZb0vNWLJvX7cHuCEq9DbjEOQN4e
  '';
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
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  # sddm will silently wait 30 sec for a fingerprint after login before timing out
  # i don't want to login with fingerprint anyway (since it wouldn't unlock kwallet)
  security.pam.services.login.fprintAuth = false;

  programs.light.enable = true;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  virtualisation.podman.enable = true;

  users.users.matt = {
    extraGroups = [ "video" ];
  };

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
