{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = with pkgs; [
    wl-clipboard
  ];

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font = "sans-serif";
    };
  };

  services.swayidle = let
    lockNow = "${pkgs.swaylock}/bin/swaylock -f";
    suspendNow = "${config.systemd.user.systemctlPath} suspend";
    isOnBattery = lib.getExe (pkgs.writeShellApplication {
      name = "is-on-battery";
      runtimeInputs = with pkgs; [coreutils];
      text = ''
        [ "$(cat /sys/class/power_supply/ACAD/online)" = "0" ] || exit 1
      '';
    });
  in {
    enable = true;
    timeouts = [
      {
        timeout = 5 * 60;
        command = "${isOnBattery} && ${lockNow}";
      }
      {
        timeout = 10 * 60;
        command = "${isOnBattery} && ${suspendNow}";
      }
      {
        timeout = 15 * 60;
        command = "${lockNow}";
      }
      {
        timeout = 30 * 60;
        command = "${suspendNow}";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${lockNow}";
      }
      {
        event = "lock";
        command = "${lockNow}";
      }
    ];
  };

  services.mako = {
    enable = true;
    font = "sans-serif 9";
    anchor = "bottom-right";
    padding = "10";
    borderRadius = 5;
    backgroundColor = "#eff1f5";
    textColor = "#4c4f69";
    borderColor = "#1e66f5";
    progressColor = "over #ccd0da";

    extraConfig = ''
      [urgency=high]
      border-color=#fe640b
    '';
  };

  services.clipman.enable = true;
}
