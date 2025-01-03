{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.raspberrypi;
in
{
  options.mjm.raspberrypi = {
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

    # they don't have a TPM, so we need this directory to be persistent
    # so we can use it for the key for systemd-creds
    mjm.state.directories = [ "/var/lib/systemd" ];
    boot.initrd.systemd.tpm2.enable = false;

    hardware.deviceTree.overlays = [
      {
        name = "rpi-poe-overlay";
        dtsFile = ./rpi-poe-overlay.dts;
      }
    ];
  };
}
