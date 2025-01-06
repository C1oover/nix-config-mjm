{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  deployment.targetHost = null;

  environment.systemPackages = lib.attrValues {
    inherit (pkgs) chrysalis sbctl;
  };

  mjm.desktop.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
      device = "/dev/disk/by-partlabel/root";
      preLVM = true;
    };
  };

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';
  services.udev.packages = [ pkgs.chrysalis ];

  services.openssh.enable = true;

  services.pipewire.wireplumber = {
    extraScripts."mjm/select-correct-profile.lua" = builtins.readFile ./select-correct-profile.lua;
    extraConfig.dell-monitor = {
      # prioritize the displayport audio over the yeti mic,
      # so that we stay on the DP audio device even when switching
      # between profiles (which changes the node name, so the
      # remembered default node gets ignored)
      "monitor.alsa.rules" = [
        {
          matches = [
            { "api.alsa.card.name" = "HDA ATI HDMI"; }
          ];
          actions = {
            update-props = {
              "priority.session" = "1200";
            };
          };
        }
      ];

      # add a custom hook before the existing profile selection
      # logic that figures out which profile matches the main
      # monitor, and chooses that one.
      "wireplumber.components" = [
        {
          name = "mjm/select-correct-profile.lua";
          type = "script/lua";
          provides = "hooks.mjm.select-correct-profile";
        }
      ];
      "wireplumber.profiles".main = {
        "hooks.mjm.select-correct-profile" = "required";
      };
    };
  };

  system.stateVersion = "24.05";
}
