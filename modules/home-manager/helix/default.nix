{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.helix;

  helix = pkgs.callPackage inputs.helix { };
  tomlFormat = pkgs.formats.toml { };

  wrappedHelix = pkgs.symlinkJoin {
    name = "helix-wrapper";
    paths = [ helix ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/hx \
        --set XDG_CONFIG_HOME ${helixConfigHome} \
        --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
    '';
  };

  helixConfigHome = pkgs.linkFarm "helix-config" {
    "helix/config.toml" = helixConfig;
    "helix/langauges.toml" = helixLanguages;
    "helix/init.scm" = "${./config/init.scm}";
    "helix/helix.scm" = "${./config/helix.scm}";
    "helix/helix" = "${./config/helix}";
  };

  helixConfig = tomlFormat.generate "helix-config.toml" cfg.settings;
  helixLanguages = tomlFormat.generate "helix-languages.toml" cfg.languages;
in
{
  options.mjm.helix = {
    enable = mkEnableOption "Helix";

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
    };

    languages = mkOption {
      type = tomlFormat.type;
      default = { };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ wrappedHelix ];
    home.sessionVariables.EDITOR = "hx";

    mjm.helix.extraPackages = with pkgs; [
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

    mjm.helix.settings = {
      theme = "catppuccin_${config.catppuccin.flavor}";
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

    mjm.helix.languages = {
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
}
