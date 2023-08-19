{
  lib,
  pkgs,
  inputs,
  ...
}: {
  home.sessionVariables.EDITOR = lib.mkForce "hx";

  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.system}.default;
    settings = {
      theme = "catppuccin_mocha";
      editor = {
        bufferline = "always";
        color-modes = true;
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };
    };
    languages = {
      language-server = {
        nil = {
          command = lib.getExe pkgs.nil;
          config.nil.formatting.command = [(lib.getExe pkgs.alejandra) "-q"];
        };
        elixir-ls = {
          command = lib.getExe pkgs.elixir-ls;
        };
        typescript-language-server = {
          command = lib.getExe pkgs.nodePackages.typescript-language-server;
        };
      };
      language = [
        {
          name = "elixir";
          auto-format = true;
        }
        {
          name = "nix";
          auto-format = true;
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nodePackages.prettier;
            args = ["--parser" "typescript"];
          };
        }
      ];
    };
  };
}
