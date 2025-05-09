{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    ;
  cfg = config.mjm.firefox;

  arkenfox = import inputs.arkenfox;

  addons = pkgs.callPackage ./addons { };
in
{
  imports = [
    arkenfox.hmModules.arkenfox
    ./search.nix
  ];

  options.mjm.firefox = {
    enable = mkEnableOption "firefox";
    package = mkPackageOption pkgs "firefox" { };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ rycee.mozilla-addons-to-nix ];

    programs.firefox = {
      enable = true;
      package = cfg.package;
      arkenfox = {
        enable = true;
        version = "133.0";
      };
      profiles.matt = {
        arkenfox = {
          enable = true;
          "0000".enable = true;
          "0100" = {
            enable = true;
            "0102"."browser.startup.page".value = 3;
            "0103"."browser.startup.homepage".value = "https://launch.midna.dev/";
          };
          "0200".enable = true;
          "0300".enable = true;
          "0600".enable = true;
          "0800".enable = true;
          "0900".enable = true;
          "1600".enable = true;
          "1700".enable = true;
          "2400".enable = true;
          "2700".enable = true;
          "4000".enable = true;
          "5000" = {
            enable = true;
            "5003"."signon.rememberSignons".enable = true;
            "5010"."browser.urlbar.suggest.bookmark".enable = true;
          };
          "6000".enable = true;
          "9000".enable = true;
        };
        settings = {
          "app.update.auto" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.onboarding.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "cookiebanners.service.mode" = 2;
          "extensions.getAddons.cache.enabled" = false;
          "extensions.pocket.enabled" = false;
          "extensions.update.autoUpdateDefault" = false;
          "extensions.update.enabled" = false;
          "privacy.donottrackheader.enabled" = true;
          "privacy.globalprivacycontrol.enabled" = true;
          "security.enterprise_roots.enabled" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "trailhead.firstrun.didSeeAboutWelcome" = true;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "widget.use-xdg-desktop-portal.location" = 1;
          "widget.use-xdg-desktop-portal.mime-handler" = 1;
          "widget.use-xdg-desktop-portal.open-uri" = 1;
          "widget.use-xdg-desktop-portal.settings" = 1;
        };
        extensions.packages = builtins.attrValues {
          inherit (pkgs.rycee.firefox-addons)
            betterttv
            bitwarden
            firefox-color
            istilldontcareaboutcookies
            libredirect
            plasma-integration
            stylus
            sidebery
            sponsorblock
            tampermonkey
            ublock-origin
            ;
          inherit (addons)
            minimaltwitter
            shinigami-eyes
            linkding-extension
            linkding-injector
            sixindicator
            ;
        };
      };
    };
  };
}
