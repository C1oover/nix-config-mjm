{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.profiles.raspberry-pi;
in
{
  options.mjm.profiles.raspberry-pi = {
    enable = mkEnableOption "Raspberry Pi hardware support";
  };

  config = mkIf cfg.enable {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb"
      "reset-raspberrypi"
    ];

    hardware.enableRedistributableFirmware = true;

    powerManagement.cpuFreqGovernor = "ondemand";
    nixpkgs.hostPlatform = "aarch64-linux";

    boot.initrd.systemd.tpm2.enable = false;

    hardware.deviceTree.overlays = [
      {
        name = "rpi-poe-overlay";
        dtsFile = ./rpi-poe-overlay.dts;
      }
    ];
  };
}
