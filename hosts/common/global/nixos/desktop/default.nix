{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.mjm.desktop;

  inherit (import ../../../../../packages { inherit pkgs; }) pragmata-pro;
in
{
  options.mjm.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      # actually element-desktop
      "jitsi-meet-1.0.8043"
    ];

    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = [
      pkgs.kdePackages.kdepim-addons
      (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png
      '')
    ];

    fonts = {
      packages = with pkgs; [
        public-sans
        open-sans
        noto-fonts
        noto-fonts-emoji
        (nerdfonts.override {
          fonts = [
            "NerdFontsSymbolsOnly"
            "Agave"
          ];
        })
        font-awesome
        cascadia-code
        ibm-plex
        iosevka
        agave
        monaspace
        (input-fonts.override { acceptLicense = true; })
        pragmata-pro
        departure-mono
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
      extraConfig.pipewire.raop-discover = {
        context.modules = [
          {
            name = "libpipewire-module-raop-discover";
            args = { };
          }
        ];
      };
    };

    # airplay requires this
    networking.firewall.allowedUDPPorts = [
      6001
      6002
    ];

    programs.kdeconnect.enable = true;
    programs.partition-manager.enable = true;
    programs.kde-pim = {
      kmail = true;
      kontact = true;
      merkuro = true;
    };

    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
    };

    boot.consoleLogLevel = 3;
    boot.plymouth = {
      enable = true;
      catppuccin.enable = true;
    };
    boot.kernelParams = [ "quiet" ];
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
      catppuccin.enable = true;
    };

    services.resolved.enable = true;
    services.avahi.enable = true;

    time.timeZone = "America/Denver";

    programs.steam.enable = true;
    services.ratbagd.enable = true;

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
