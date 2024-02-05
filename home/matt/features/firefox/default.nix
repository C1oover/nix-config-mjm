{
  pkgs,
  lib,
  inputs,
  ...
}: let
  addons = pkgs.callPackage ./addons {};
  firefox =
    if pkgs.stdenv.isLinux
    then pkgs.firefox
    else pkgs.firefox-bin;
in {
  home.packages = with pkgs; [
    nur.repos.rycee.mozilla-addons-to-nix
  ];

  programs.firefox = {
    enable = true;
    package = firefox;
    profiles.matt = {
      settings = {
        "app.update.auto" = false;
        "browser.discovery.enabled" = false;
        "browser.formfill.enable" = false;
        "browser.onboarding.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.startup.homepage" = "https://homelab.midna.dev/";
        "cookiebanners.service.mode" = 2;
        "extensions.activeThemeID" = "{c827c446-3d00-4160-a992-3ebcbe6d81a6}";
        "extensions.getAddons.cache.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "extensions.pocket.enabled" = false;
        "extensions.update.autoUpdateDefault" = false;
        "extensions.update.enabled" = false;
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "security.enterprise_roots.enabled" = true;
        "signon.autofillForms" = false;
        "signon.rememberSignons" = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "trailhead.firstrun.didSeeAboutWelcome" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.use-xdg-desktop-portal.location" = 1;
        "widget.use-xdg-desktop-portal.mime-handler" = 1;
        "widget.use-xdg-desktop-portal.open-uri" = 1;
        "widget.use-xdg-desktop-portal.settings" = 1;
      };
      extensions = with pkgs.nur.repos; [
        rycee.firefox-addons.betterttv
        rycee.firefox-addons.bitwarden
        rycee.firefox-addons.firefox-color
        rycee.firefox-addons.stylus
        rycee.firefox-addons.sidebery
        rycee.firefox-addons.tampermonkey
        rycee.firefox-addons.ublock-origin
        addons.minimaltwitter
        addons.shinigami-eyes
        addons.linkding-extension
        addons.linkding-injector
        addons.catppuccin-latte-mauve
        addons.sixindicator
      ];
      userChrome = ''
        ${builtins.readFile (inputs.firefox-csshacks + /chrome/window_control_placeholder_support.css)}
        ${lib.optionalString pkgs.stdenv.isDarwin (builtins.readFile (inputs.firefox-csshacks + /chrome/hide_tabs_toolbar_osx.css))}
        ${lib.optionalString pkgs.stdenv.isLinux ''
          #TabsToolbar{ visibility: collapse !important }
        ''}
      '';
      search.force = true;
      search.engines = {
        "MyNixOS" = {
          urls = [
            {
              template = "https://mynixos.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];

          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@n"];
        };
        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "type";
                  value = "packages";
                }
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];

          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@np"];
        };
        "Nix Options" = {
          urls = [
            {
              template = "https://search.nixos.org/options";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];

          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@no"];
        };
        "Links" = {
          urls = [
            {
              template = "https://links.midna.dev/bookmarks";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          definedAliases = ["@l"];
        };
        "Bing".metadata.hidden = true;
        "Google".metadata.alias = "@g";
      };
    };
  };
}
