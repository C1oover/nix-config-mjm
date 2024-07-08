{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lanzaboote = import inputs.lanzaboote;
in
{
  imports = [
    lanzaboote.nixosModules.lanzaboote

    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ./nvk.nix
  ];

  nixpkgs.overlays = [
    (self: super: {
      firefox-unwrapped = super.firefox-unwrapped.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches ++ [
          (pkgs.fetchpatch {
            url = "https://phabricator.services.mozilla.com/D214883?id=887831&download=true";
            hash = "sha256-wIukbMDp0olbY8j+w+T4QcKjQSi3gj5RzaXKC6ctw0I=";
          })
          (pkgs.fetchpatch {
            url = "https://phabricator.services.mozilla.com/D214884?id=887832&download=true";
            hash = "sha256-2CAIVWPUSoNYcjMR22abv5+ODZeKQFXizB3L0vC73ss=";
          })
          (pkgs.fetchpatch {
            url = "https://phabricator.services.mozilla.com/D214885?id=887833&download=true";
            hash = "sha256-qN3aqDZTReG090luS8fI138yzQ8rq3oHrMArEzHDr8A=";
          })
        ];
      });
    })
  ];

  deployment.phase = null;

  # services.displayManager.defaultSession = "plasmax11";

  environment.systemPackages = [ pkgs.sbctl ];

  mjm.desktop.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "uranus";
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/71a879cc-7f86-47c7-9dec-1978f0af0e66";
      preLVM = true;
    };
  };

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
