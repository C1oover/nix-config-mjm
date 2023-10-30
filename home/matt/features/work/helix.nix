{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};
in {
  imports = [
    ../helix
  ];

  # cmake is needed to build some elixir deps
  # if it's not in the path, elixir-ls might just not work
  home.packages = with pkgs; [cmake];

  # manually link this into ~/Projects/slab/.helix/languages.toml
  xdg.configFile."helix/slab/languages.toml".source = tomlFormat.generate "slab-languages.toml" {
    language-server.elixir-ls.command = let
      # use an official elixir-ls release so that it just runs with whatever elixir version
      # is in the environment. since we use asdf for the version, we can't ensure the elixir
      # version in nixpkgs matches.
      version = "0.17.5";
      elixir-ls = pkgs.fetchzip {
        url = "https://github.com/elixir-lsp/elixir-ls/releases/download/v${version}/elixir-ls-v${version}.zip";
        hash = "sha256-hhPUCGxYIp2IQu47xhAoTLjYHAytj4PW38OkQJt2xy4=";
        stripRoot = false;
      };
    in "${elixir-ls}/language_server.sh";
  };
}
