{
  pkgs,
  lib,
  config,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };

    services.dbus.packages = [ pkgs.kdePackages.kpmcore ];
    environment.systemPackages = [
      pkgs.kdePackages.kpmcore
      pkgs.kdePackages.partitionmanager
    ];

    fonts = {
      packages = with pkgs; [
        public-sans
        open-sans
        noto-fonts
        noto-fonts-emoji
        (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
        font-awesome
        cascadia-code
        ibm-plex
        iosevka
        agave
        outputs.packages.${pkgs.system}.pragmata-pro
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [
            "PragmataPro Mono"
            "Noto Sans Mono"
          ];
          sansSerif = [ "Noto Sans" ];
          serif = [ "Noto Serif" ];
        };
      };
    };

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    programs.kdeconnect.enable = true;

    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
    };

    boot.consoleLogLevel = 3;
    boot.plymouth = {
      enable = true;
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
      theme = "catppuccin-mocha";
    };
    boot.kernelParams = [ "quiet" ];
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
      # catppuccin frappe
      colors = [
        "303446" # base
        "e78284" # red
        "a6d189" # green
        "e5c890" # yellow
        "8caaee" # blue
        "f4b8e4" # pink
        "81c8be" # teal
        "b5bfe2" # subtext1
        "626880" # surface2
        "e78284" # red
        "a6d189" # green
        "e5c890" # yellow
        "8caaee" # blue
        "f4b8e4" # pink
        "81c8be" # teal
        "a5adce" # subtext0
      ];
    };

    services.resolved.enable = true;
    services.avahi.enable = true;

    time.timeZone = "America/Denver";

    programs.steam.enable = true;
  };
}
