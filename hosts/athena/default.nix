{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    "${inputs.nixos-apple-silicon}/apple-silicon-support"
  ];

  mjm.username = "mjm";

  networking.hostName = "athena";

  boot.loader.systemd-boot.enable = true;

  mjm.desktop.enable = true;
  mjm.desktop.plasma.enable = true;

  # it's pretty easy to blow up the ram on this thing with the default max-jobs
  nix.settings.max-jobs = 4;

  # without this, it's gonna use llvmpipe and the performance will be just total ass
  hardware.asahi.useExperimentalGPUDriver = true;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # erofs doesn't seem to be available here?
  system.etc.overlay.enable = lib.mkForce false;

  # this is a little sketch, but for the moment it seems like the least bad way to let
  # this system build in CI. basically, if this firmware directory can't be found, it
  # just won't be used, but the system will otherwise build fine.
  hardware.asahi.extractPeripheralFirmware =
    config.hardware.asahi.peripheralFirmwareDirectory != null;

  system.stateVersion = "25.05";
}
