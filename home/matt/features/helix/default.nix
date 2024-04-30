{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # FIXME find a way to be explicit about the system helix is built for
  helix = import inputs.helix;
in
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    catppuccin = {
      enable = true;
      useItalics = true;
    };
    package = helix.override {
      includeGrammarIf = { source, ... }: !(lib.hasPrefix "https://git.sr.ht/" source.git);
    };
    extraPackages = with pkgs; [
      elixir-ls
      marksman
      nil
      nixfmt-rfc-style
      shellcheck
      shfmt
      vscode-langservers-extracted
      nodePackages.bash-language-server
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
    ];
    settings = {
      editor = {
        bufferline = "always";
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        idle-timeout = 100;
        indent-guides.render = true;
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        true-color = true;
        whitespace.render.newline = "all";
      };
      keys.normal = {
        "]".b = ":buffer-next";
        "[".b = ":buffer-previous";
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
          auto-format = true;
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
}
