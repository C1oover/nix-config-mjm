{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkForce mkIf;
  cfg = config.mjm.desktop;
in
{
  imports = [ ../../common/desktop.nix ];

  config = mkIf cfg.enable {
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
        noto-fonts-emoji
        nerd-fonts.agave
        font-awesome
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
    boot.plymouth.enable = true;
    boot.kernelParams = [ "quiet" ];
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
      keyMap = "us";
    };
    catppuccin.plymouth.enable = true;
    catppuccin.tty.enable = true;

    services.resolved.enable = true;
    services.avahi.enable = true;

    time.timeZone = "America/Denver";

    programs.steam.enable = true;
    services.ratbagd.enable = true;
    hardware.bluetooth.enable = true;

    services.yubikey-agent.enable = true;
    systemd.user.services.yubikey-agent.wantedBy = mkForce [ "graphical-session.target" ];
    systemd.services.NetworkManager-wait-online.enable = false;

    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    mjm.state.directories = [ "/var/lib/libvirt" ];
    virtualisation.docker.enable = true;

    users.users.matt.extraGroups = [
      "libvirtd"
      "docker"
    ];
  };
}
