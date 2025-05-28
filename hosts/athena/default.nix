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
  hardware.asahi.withRust = true;

  boot.kernelPatches = [
    {
      name = "enable-erofs";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        EROFS_FS = module;
        EROFS_FS_XATTR = yes;
        EROFS_FS_POSIX_ACL = yes;
        EROFS_FS_SECURITY = yes;
        EROFS_FS_BACKED_BY_FILE = yes;
        EROFS_FS_ZIP = yes;
        EROFS_FS_ZIP_LZMA = yes;
        EROFS_FS_ZIP_DEFLATE = yes;
        EROFS_FS_ZIP_ZSTD = yes;
        EROFS_FS_ONDEMAND = yes;
      };
    }
  ];

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # this is a little sketch, but for the moment it seems like the least bad way to let
  # this system build in CI. basically, if this firmware directory can't be found, it
  # just won't be used, but the system will otherwise build fine.
  hardware.asahi.extractPeripheralFirmware =
    config.hardware.asahi.peripheralFirmwareDirectory != null;

  system.stateVersion = "25.05";
}
