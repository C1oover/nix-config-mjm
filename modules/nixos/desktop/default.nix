{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkForce mkIf;
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

    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
    };

    programs.steam.enable = true;
    services.ratbagd.enable = true;
    hardware.bluetooth.enable = true;

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];

    mjm.state.directories = mkIf config.services.fprintd.enable [
      "/var/lib/fprint"
    ];
  };
}
