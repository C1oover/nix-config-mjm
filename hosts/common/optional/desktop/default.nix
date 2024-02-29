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
    boot.kernelParams = [
      "quiet"
      # catppuccin mocha
      "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
      "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
      "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
    ];
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
    };

    services.resolved.enable = true;
    services.avahi.enable = true;

    time.timeZone = "America/Denver";

    programs.steam.enable = true;
  };
}
