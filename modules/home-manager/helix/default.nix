{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.helix;

  helix = pkgs.callPackage inputs.helix { };
in
{
  options.mjm.helix = {
    enable = mkEnableOption "Helix";
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      package = helix;
      extraPackages = with pkgs; [
        elixir-ls
        marksman
        nil
        nixd
        nixfmt-rfc-style
        # racket
        shellcheck
        shfmt
        vscode-langservers-extracted
        bash-language-server
        nodePackages.prettier
        nodePackages.typescript-language-server
        nodePackages.yaml-language-server
      ];
      settings = {
        editor = {
          auto-save.focus-lost = true;
          bufferline = "always";
          cursorline = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          idle-timeout = 100;
          indent-guides.render = true;
          inline-diagnostics = {
            cursor-line = "hint";
            other-lines = "error";
          };
          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };
          statusline.right = [
            "version-control"
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-encoding"
          ];
          true-color = true;
          whitespace.render.newline = "all";
        };
      };
      languages = {
        language-server = {
          bash-language-server = {
            config.bashIde.backgroundAnalysisMaxFiles = 0;
          };
          nil = {
            config.nil.formatting.command = [
              "nixfmt"
              "-q"
            ];
          };
          nixd = {
            command = "nixd";
            config.nixd = {
              formatting.command = [
                "nixfmt"
                "-q"
              ];
            };
          };
          yaml-language-server = {
            config.yaml = {
              format.enable = true;
              customTags = [ "!reference sequence" ];
            };
          };
        };
        language = [
          {
            name = "bash";
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            auto-format = true;
            formatter = {
              command = "shfmt";
              args = [
                "-i"
                "2"
              ];
            };
          }
          {
            name = "elixir";
            auto-format = true;
          }
          {
            name = "heex";
            auto-format = true;
          }
          {
            name = "javascript";
            auto-format = true;
            formatter = {
              command = "prettier";
              args = [
                "--parser"
                "typescript"
              ];
            };
          }
          {
            name = "nix";
            language-servers = [ "nixd" ];
            auto-format = true;
          }
          {
            name = "scheme";
            auto-format = true;
            formatter = {
              command = "raco";
              args = [
                "fmt"
                "-i"
              ];
            };
          }
          {
            name = "yaml";
            auto-format = true;
            formatter = {
              command = "prettier";
              args = [
                "--parser"
                "yaml"
              ];
            };
          }
        ];
      };
    };

    catppuccin.helix = {
      enable = true;
      useItalics = true;
    };

    xdg.configFile."helix" = {
      source = ./config;
      recursive = true;
    };
  };
}
