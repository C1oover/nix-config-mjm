{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce mkIf mkOverride;
  cfg = config.mjm.desktop;
in
{
  imports = [
    ../../common/desktop.nix

    ./boot.nix
    ./fonts.nix
    ./network.nix
    ./plasma.nix
    ./sound.nix
    ./virtualisation.nix
  ];

  config = mkIf cfg.enable {
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

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];

    mjm.state.directories = mkIf config.services.fprintd.enable [
      "/var/lib/fprint"
    ];

    boot.binfmt.emulatedSystems = mkIf (pkgs.system == "x86_64-linux") [ "aarch64-linux" ];
  };
}
