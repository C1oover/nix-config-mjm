{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe mkEnableOption mkIf;
  cfg = config.mjm.work;

  slab = pkgs.writers.writeNuBin ",slab" (
    pkgs.replaceVars ./slab.nu {
      sqlite3 = getExe pkgs.sqlite;
      snappy-decompress = "${pkgs.snappy-decompress}";
    }
  );
in
{
  imports = [
    ./helix.nix
    ./k9s.nix
  ];

  options.mjm.work = {
    enable = mkEnableOption "work-specific configs";
  };

  config = mkIf cfg.enable {
    programs.git.userEmail = "matt@slab.com";

    home.packages = builtins.attrValues {
      inherit slab;
      inherit (pkgs) cloudflared google-cloud-sdk;
    };

    programs.fish.shellInitLast = ''
      source ~/.asdf/asdf.fish
    '';
    xdg.configFile."fish/completions/asdf.fish".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.asdf/completions/asdf.fish";

    # orbstack likes to replace these, very annoying
    xdg.configFile."fish/completions/docker.fish".force = true;
    xdg.configFile."fish/completions/kubectl.fish".force = true;

    programs.nushell.extraConfig = ''
      def ",t all" [] {
        docker compose exec slab_1 mix test.all
      }

      def ",t last" [] {
        let last_test = open ~/.cache/mjm/last_test --raw | decode utf-8 | str trim
        docker compose exec slab_1 mix test $last_test
      }

      def ",t" [] {
        mkdir ~/.cache/mjm
        let test_path = ls test/**/*_test.exs | get name | str join (char nl) | fzf | tee { save -f ~/.cache/mjm/last_test }
        docker compose exec slab_1 mix test $test_path
      }

      $env.ASDF_DIR = ($env.HOME | path join '.asdf')
      source ${config.home.homeDirectory}/.asdf/asdf.nu
    '';

    programs.kitty.darwinLaunchOptions = [
      "--session"
      "${./kitty-session-slab}"
    ];

    xdg.configFile."zellij/layouts/slab.kdl".source = ./work.kdl;
  };
}
