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
            url = "https://phabricator.services.mozilla.com/D214883?download=true";
            hash = "sha256-/twQc6svBiojaceDrUg/qIfgUT5gNfj4s4yM5ldpPz4=";
          })
          (pkgs.fetchpatch {
            url = "https://phabricator.services.mozilla.com/D214884?download=true";
            hash = "sha256-5RNr4plnLP1BRll2J/dzCg64/xtqJoQTUh94AmqZ9/w=";
          })
          (pkgs.fetchpatch {
            url = "https://phabricator.services.mozilla.com/D214885?download=true";
            hash = "sha256-8XdNDPjriIwLRn0UB7DYmmXkw1MHzlwiCrnng+Oh494=";
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
