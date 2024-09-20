{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.work;

  snappy-decompress =
    pkgs.writers.writePython3 "snappy-decompress" { libraries = [ pkgs.python3Packages.cramjam ]; }
      ''
        import sys
        import cramjam

        input = sys.stdin.buffer.read()
        sys.stdout.buffer.write(bytes(cramjam.snappy.decompress_raw(input[:-1])))
      '';

  slab = pkgs.writers.writeNuBin ",slab" ''
    def --wrapped "main ssh" [...rest] {
      npm run docker:ssh ...$rest
    }

    def "main restart" [] {
      npm run docker:down
      docker compose up -d
      npm run docker:logs -- --no-log-prefix
    }

    def --wrapped "main up" [...rest] {
      docker compose up -d ...$rest
    }

    def "main token" [] {
      cd (mktemp -d)
      cp `~/Library/Application Support/Firefox/Profiles/matt/storage/default/https+++matt.slabdev.com/ls/data.sqlite` data.sqlite
      ${pkgs.sqlite}/bin/sqlite3 data.sqlite "select value from data where key = 'CapacitorStorage.authToken'" | ${snappy-decompress}
    }

    def main [] {}
  '';
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

    home.shellAliases = {
      slab-restart = "npm run docker:down && slab-up && npm run docker:logs -- --no-log-prefix";
      slab-up = "docker compose up -d";
      slab-ssh = "npm run docker:ssh";
      piex = "slab-ssh bin/phx-iex";
    };
    programs.nushell.extraConfig = ''
      alias piex = ,slab ssh bin/phx-iex

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
  };
}
