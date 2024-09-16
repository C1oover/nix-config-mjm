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
    optionalString
    ;
  cfg = config.mjm.firefox;

  arkenfox = import inputs.arkenfox;

  addons = pkgs.callPackage ./addons { };
in
{
  imports = [ arkenfox.hmModules.arkenfox ];

  options.mjm.firefox = {
    enable = mkEnableOption "firefox";
    package = mkPackageOption pkgs "firefox" { };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ nur.repos.rycee.mozilla-addons-to-nix ];

    programs.firefox = {
      enable = true;
      package = cfg.package;
      arkenfox = {
        enable = true;
        version = "128.0";
      };
      profiles.matt = {
        arkenfox = {
          enable = true;
          "0000".enable = true;
          "0100" = {
            enable = true;
            "0102"."browser.startup.page".value = 3;
            "0103"."browser.startup.homepage".value = "https://homelab.midna.dev/";
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
        extensions =
          with pkgs.nur.repos;
          builtins.attrValues {
            inherit (rycee.firefox-addons)
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
        userChrome = ''
          ${builtins.readFile (inputs.firefox-csshacks + /chrome/window_control_placeholder_support.css)}
          ${optionalString pkgs.stdenv.isDarwin (
            builtins.readFile (inputs.firefox-csshacks + /chrome/hide_tabs_toolbar_osx.css)
          )}
          ${optionalString pkgs.stdenv.isLinux (
            builtins.readFile (inputs.firefox-csshacks + /chrome/hide_tabs_toolbar.css)
          )}
        '';
        search.force = true;
        search.default = "SearXNG";
        search.engines =
          let
            mkSearchix =
              {
                type ? "options",
                project,
                alias,
              }:
              {
                urls = [
                  {
                    template = "https://searchix.alanpearce.eu/${type}/${project}/search";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@${alias}" ];
              };
          in
          {
            "SearXNG" = {
              urls = [
                {
                  template = "https://searx.org/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
            };
            "Nix Packages" = mkSearchix {
              type = "packages";
              project = "nixpkgs";
              alias = "np";
            };
            "NixOS Options" = mkSearchix {
              project = "nixos";
              alias = "no";
            };
            "nix-darwin Options" = mkSearchix {
              project = "darwin";
              alias = "nd";
            };
            "Home Manager Options" = mkSearchix {
              project = "home-manager";
              alias = "nh";
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
              definedAliases = [ "@l" ];
            };
            "Bing".metadata.hidden = true;
            "Google".metadata.alias = "@g";
          };
      };
    };
  };
}
