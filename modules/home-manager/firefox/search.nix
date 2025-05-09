{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.firefox;

  mkSearchix =
    {
      name,
      type ? "options",
      project,
      alias,
    }:
    {
      inherit name;
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
  config = mkIf cfg.enable {
    programs.firefox.profiles.matt.search = {
      force = true;
      default = "searxng";
      engines = {
        searxng = {
          name = "SearXNG";
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
        noogle = {
          name = "Noogle";
          definedAliases = [ "@n" ];
          urls = [
            {
              template = "https://noogle.dev/q";
              params = [
                {
                  name = "term";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
        };
        node-dashboard = {
          name = "Node Dashboard";
          definedAliases = [ "@node" ];
          urls = [
            {
              template = "https://graphs.midna.dev/d/rYdddlPWk/node-exporter-full";
              params = [
                {
                  name = "orgId";
                  value = "1";
                }
                {
                  name = "from";
                  value = "now-1h";
                }
                {
                  name = "to";
                  value = "now";
                }
                {
                  name = "refresh";
                  value = "1m";
                }
                {
                  name = "var-job";
                  value = "integrations/unix";
                }
                {
                  name = "var-node";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
        };
        log-service = {
          name = "Service Logs";
          definedAliases = [ "@logs" ];
          urls = [
            {
              template = "https://graphs.midna.dev/a/grafana-lokiexplore-app/explore/service/{searchTerms}/logs";
              params = [
                {
                  name = "from";
                  value = "now-1h";
                }
                {
                  name = "to";
                  value = "now";
                }
                {
                  name = "var-filters";
                  value = "service_name|=|{searchTerms}";
                }
              ];
            }
          ];
        };
        log-host = {
          name = "Host Logs";
          definedAliases = [ "@logh" ];
          urls = [
            {
              template = "https://graphs.midna.dev/a/grafana-lokiexplore-app/explore/hostname/{searchTerms}/logs";
              params = [
                {
                  name = "from";
                  value = "now-1h";
                }
                {
                  name = "to";
                  value = "now";
                }
                {
                  name = "var-filters";
                  value = "hostname|=|{searchTerms}";
                }
              ];
            }
          ];
        };
        nix-packages = mkSearchix {
          name = "Nix Packages";
          type = "packages";
          project = "nixpkgs";
          alias = "np";
        };
        nixos-options = mkSearchix {
          name = "NixOS Options";
          project = "nixos";
          alias = "no";
        };
        nix-darwin-options = mkSearchix {
          name = "nix-darwin Options";
          project = "darwin";
          alias = "nd";
        };
        home-manager-options = mkSearchix {
          name = "Home Manager Options";
          project = "home-manager";
          alias = "nh";
        };
        linkding = {
          name = "Links";
          definedAliases = [ "@l" ];
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
        };
        wowhead-classic = {
          name = "WowHead Classic";
          definedAliases = [ "@wh" ];
          urls = [
            {
              template = "https://www.wowhead.com/classic/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
        };
        bing.metaData.hidden = true;
        google.metaData.alias = "@g";
      };
    };
  };
}
