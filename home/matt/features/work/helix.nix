{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};
  tomlFormat = pkgs.formats.toml {};
in {
  imports = [
    ../helix
  ];

  # cmake is needed to build some elixir deps
  # if it's not in the path, elixir-ls might just not work
  home.packages = with pkgs; [cmake];

  programs.helix = let
    efmConfig = yamlFormat.generate "efm-config.yml" {
      version = 2;
      root-markers = [".git/"];
      languages.elixir = [
        {
          lint-command = "mix credo suggest --format=flycheck --read-from-stdin";
          lint-stdin = true;
          lint-formats = [
            "%f:%l:%c: %t: %m"
            "%f:%l: %t: %m"
          ];
          root-markers = [
            "mix.lock"
            "mix.exs"
          ];
        }
      ];
    };
  in {
    extraPackages = with pkgs; [efm-langserver];
    languages = {
      language-server.efm = {
        command = "efm-langserver";
        args = ["-c" "${efmConfig}"];
      };
    };
  };

  # manually link this into ~/Projects/slab/.helix/languages.toml
  xdg.configFile."helix/slab/languages.toml".source = tomlFormat.generate "slab-languages.toml" {
    language-server.elixir-ls.command = let
      # use an official elixir-ls release so that it just runs with whatever elixir version
      # is in the environment. since we use asdf for the version, we can't ensure the elixir
      # version in nixpkgs matches.
      version = "0.18.1";
      elixir-ls = pkgs.fetchzip {
        url = "https://github.com/elixir-lsp/elixir-ls/releases/download/v${version}/elixir-ls-v${version}.zip";
        hash = "sha256-i4oBD2/ePBjZ3NfrFnVC19ztWquQiLKeMqqMeenops4=";
        stripRoot = false;
      };
    in "${elixir-ls}/language_server.sh";

    language = [
      {
        name = "elixir";
        language-servers = [
          {
            name = "efm";
            only-features = ["diagnostics"];
          }
          {name = "elixir-ls";}
        ];
      }
    ];
  };
}
