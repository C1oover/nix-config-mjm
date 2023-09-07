{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:NixOS/nixos-hardware";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.home-manager.follows = "home-manager";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    nixvim.url = "github:pta2002/nixvim";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    git-branchless = {
      url = "github:arxanas/git-branchless";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
    jujutsu = {
      url = "github:martinvonz/jj/v0.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-zsh = {
      url = "github:catppuccin/zsh-syntax-highlighting";
      flake = false;
    };
    catppuccin-k9s = {
      url = "github:catppuccin/k9s";
      flake = false;
    };
    catppuccin-newsboat = {
      url = "github:catppuccin/newsboat";
      flake = false;
    };
    catppuccin-i3 = {
      url = "github:catppuccin/i3";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        ./hosts
        ./modules
        ./packages
        ./terraform
      ];

      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {
        pkgs,
        lib,
        ...
      }: {
        devenv.shells.default = {
          pre-commit = {
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
            };

            excludes = [
              "home/matt/features/firefox/addons/addons.nix"
            ];
          };
          dotenv.disableHint = true;
        };

        formatter = pkgs.alejandra;

        apps.ci-flake-update.program = lib.getExe (pkgs.writeShellApplication {
          name = "ci-flake-update";
          runtimeInputs = with pkgs; [curl jq nix git];
          text = ''
            function latest_nixpkgs() {
              curl -s 'https://monitoring.nixos.org/prometheus/api/v1/query?query=channel_revision%7Bchannel%3D%22nixpkgs-unstable%22%7D' \
                | jq -r '.data.result[0].metric.revision'
            }

            function my_nixpkgs() {
              nixpkgs_name="$(nix flake metadata . --json | jq -r '.locks.nodes.root.inputs.nixpkgs')"
              nix flake metadata . --json | jq -r ".locks.nodes.$nixpkgs_name.locked.rev"
            }

            latest="$(latest_nixpkgs)"
            mine="$(my_nixpkgs)"

            echo "latest: $latest"
            echo "mine: $mine"

            if [ "$latest" = "$mine" ]; then
              echo "no updates: all done"
              exit 0
            fi

            echo "latest nixpkgs doesn't match my version. updating..."
            nix flake update
            git config user.email "gitlab@matt.mattmoriarity.com"
            git config user.name "GitLab Automation"
            git add flake.lock
            git commit -m "nix flake update"
            git remote add gitlab "https://ci:$FLAKE_UPDATE_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git"
            git push gitlab HEAD:main
          '';
        });
      };
    };
}
