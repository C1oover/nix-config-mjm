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
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

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

    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
    };

    boot.consoleLogLevel = 3;
    boot.plymouth = {
      enable = true;
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = config.catppuccin.flavour; }) ];
      theme = "catppuccin-${config.catppuccin.flavour}";
    };
    boot.kernelParams = [ "quiet" ];
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
      catppuccin.enable = true;
    };

    services.resolved.enable = true;
    services.avahi.enable = true;

    time.timeZone = "America/Denver";

    programs.steam.enable = true;

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];
  };
}
