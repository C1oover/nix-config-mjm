{
  pkgs,
  lib,
  config,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (
          kfinal: kprev: {
            kservice = kprev.kservice.overrideAttrs (oldAttrs: {
              patches = oldAttrs.patches ++ [ ./ksycoca.patch ];
            });
          }
        );
      })
    ];

    services.xserver = {
      enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };

    services.dbus.packages = [ pkgs.kdePackages.kpmcore ];
    environment.systemPackages =
      [
        pkgs.kdePackages.kpmcore
        pkgs.kdePackages.partitionmanager
        (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png
        '')
      ]
      ++ (with pkgs.kdePackages; [
        akonadi
        kdepim-runtime
        akonadiconsole
        kmail-account-wizard

        kmail
        kontact
        merkuro
        kdepim-addons
      ]);

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

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];
  };
}
