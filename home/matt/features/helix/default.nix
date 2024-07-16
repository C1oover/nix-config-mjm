{
  pkgs,
  inputs,
  osConfig,
  ...
}:
let
  helix = (import inputs.helix).packages.${pkgs.system}.default;
in
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    catppuccin = {
      enable = true;
      useItalics = true;
    };
    package = helix;
    extraPackages = with pkgs; [
      elixir-ls
      marksman
      nil
      nixfmt-rfc-style
      shellcheck
      shfmt
      vscode-langservers-extracted
      bash-language-server
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      osConfig.programs.nushell.wrappedPackage
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

  xdg.configFile."helix" = {
    source = ./config;
    recursive = true;
  };
}
