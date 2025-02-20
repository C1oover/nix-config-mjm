{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.proxmox-vm;
in
{
  options.mjm.proxmox-vm = {
    enable = mkEnableOption "Proxmox VM support";
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = [
      "9p"
      "9pnet_virtio"
      "ata_piix"
      "sd_mod"
      "sr_mod"
      "uhci_hcd"
      "virtio_blk"
      "virtio_mmio"
      "virtio_net"
      "virtio_pci"
      "virtio_scsi"
    ];
    boot.initrd.kernelModules = [
      "virtio_balloon"
      "virtio_console"
      "virtio_rng"
      "virtio_gpu"
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

    services.qemuGuest.enable = true;
  };
}
