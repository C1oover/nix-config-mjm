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
    package = pkgs.swaylock-effects;
    settings = {
      font = "sans-serif";
      screenshots = true;
      clock = true;
      fade-in = 0.2;
      effect-blur = "7x5";
      indicator = true;
    };
  };

  services.swayidle = let
    lockNow = "${lib.getExe config.programs.swaylock.package} -f";
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
