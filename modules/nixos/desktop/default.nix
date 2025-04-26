{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOverride;
  cfg = config.mjm.desktop;
in
{
  imports = [
    ../../common/desktop.nix

    ./boot.nix
    ./chrysalis.nix
    ./cosmic.nix
    ./fonts.nix
    ./network.nix
    ./plasma.nix
    ./sound.nix
    ./ssh-tpm.nix
    ./virtualisation.nix
  ];

  config = mkIf cfg.enable {
    documentation.enable = true;
    documentation.man.generateCaches = true;

    time.timeZone = "America/Denver";

    deployment.targetHost = mkOverride 900 null;

    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
    };

    programs.steam.enable = true;
    services.ratbagd.enable = true;
    hardware.bluetooth.enable = true;

    # Allow desktop mouse and keyboard to wake the system
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
    '';

    mjm.state.directories = mkIf config.services.fprintd.enable [
      "/var/lib/fprint"
    ];

    boot.binfmt.emulatedSystems = mkIf (pkgs.system == "x86_64-linux") [ "aarch64-linux" ];
  };
}
