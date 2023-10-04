{
  self,
  inputs,
  withSystem,
  ...
}: let
  inherit (self) outputs;
  mkDarwin = arch: modules:
    inputs.darwin.lib.darwinSystem {
      inherit modules;

      system = "${arch}-darwin";
      inputs = {inherit (inputs) darwin nixpkgs;};
      specialArgs = {inherit inputs outputs;};
    };
  mkNixos = modules:
    inputs.nixos.lib.nixosSystem {
      inherit modules;
      specialArgs = {inherit inputs outputs;};
    };
in {
  flake = {
    darwinConfigurations = {
      mars = mkDarwin "x86_64" [./mars];
      athena = mkDarwin "aarch64" [./athena];
    };

    nixosConfigurations = {
      persephone = mkNixos [./persephone];
      nyx = mkNixos [./nyx];
      uranus = mkNixos [./uranus];

      # Hashistack control plane VMs
      megaera = mkNixos [./megaera];
      tisiphone = mkNixos [./tisiphone];
      alecto = mkNixos [./alecto];

      # Raspberry Pis
      arges = mkNixos [./arges];
      brontes = mkNixos [./brontes];
      steropes = mkNixos [./steropes];

      # Other Proxmox VMs
      hypnos = mkNixos [./hypnos];
      helios = mkNixos [./helios];

      # Proxmox LXC containers
      orion = mkNixos [./orion];
      nemesis = mkNixos [./nemesis];
      aion = mkNixos [./aion];
      gaia = mkNixos [./gaia];
      rhea = mkNixos [./rhea];
      cronus = mkNixos [./cronus];
      phoebe = mkNixos [./phoebe];
      themis = mkNixos [./themis];
      thanatos = mkNixos [./thanatos];
    };

    checks = let
      mkDeployCheck = system: nodes:
        withSystem system ({pkgs, ...}:
          pkgs.symlinkJoin {
            name = "deploy-x86_64";
            paths = map (name:
              pkgs.runCommand "deploy-${name}" {} ''
                mkdir $out
                ln -s ${outputs.deploy.nodes.${name}.profiles.system.path} $out/deploy-${name}
              '')
            nodes;
          });
    in {
      x86_64-linux.deploy-1 = mkDeployCheck "x86_64-linux" ["aion" "cronus" "gaia" "nemesis" "orion"];
      x86_64-linux.deploy-2 = mkDeployCheck "x86_64-linux" ["phoebe" "rhea" "thanatos" "themis"];
      x86_64-linux.deploy-3 = mkDeployCheck "x86_64-linux" ["alecto" "helios" "hypnos" "megaera" "tisiphone"];
      aarch64-linux.deploy = mkDeployCheck "aarch64-linux" ["arges" "brontes" "nyx" "steropes"];
    };

    deploy = {
      user = "root";
      sshUser = "matt";
      sshOpts = ["-i" "/home/matt/.ssh/yubikey-cert.pub"];
      nodes = let
        mkNode = name: cfg: let
          nixos = outputs.nixosConfigurations.${name};
        in
          {
            hostname = "${nixos.config.networking.hostName}.home.mattmoriarity.com";
            profiles.system.path = inputs.deploy-rs.lib.${nixos.config.nixpkgs.hostPlatform.system}.activate.nixos nixos;
          }
          // cfg;
      in {
        aion = mkNode "aion" {};
        alecto = mkNode "alecto" {};
        arges = mkNode "arges" {};
        brontes = mkNode "brontes" {};
        cronus = mkNode "cronus" {};
        gaia = mkNode "gaia" {};
        helios = mkNode "helios" {};
        hypnos = mkNode "hypnos" {};
        megaera = mkNode "megaera" {};
        nemesis = mkNode "nemesis" {};
        nyx = mkNode "nyx" {
          hostname = "nyx.mattmoriarity.com";
        };
        orion = mkNode "orion" {};
        phoebe = mkNode "phoebe" {};
        rhea = mkNode "rhea" {};
        steropes = mkNode "steropes" {};
        thanatos = mkNode "thanatos" {};
        themis = mkNode "themis" {};
        tisiphone = mkNode "tisiphone" {};
      };
    };
  };

  perSystem = {
    pkgs,
    lib,
    system,
    inputs',
    ...
  }: let
    deploy-rs = inputs'.deploy-rs.packages.default;
  in {
    devenv.shells.default = {
      packages = [deploy-rs];
    };

    packages.deploy-prebuild = pkgs.writeShellApplication {
      name = "deploy-prebuild";
      runtimeInputs = [inputs'.nix-fast-build.packages.default];
      text = ''
        if [ "$1" = "arm64" ]; then
          shift
          nix-fast-build -f ".#checks.aarch64-linux.deploy" --eval-max-memory-size 2048 --eval-workers 4 "$@"
        else
          shift
          nix-fast-build -f ".#checks.x86_64-linux.deploy-1" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          nix-fast-build -f ".#checks.x86_64-linux.deploy-2" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          nix-fast-build -f ".#checks.x86_64-linux.deploy-3" --eval-max-memory-size 2048 --eval-workers 4 "$@"
        fi
      '';
    };

    apps.deploy.program = lib.getExe (pkgs.writeShellApplication {
      name = "deploy";
      runtimeInputs = [pkgs.coreutils pkgs.openssh pkgs.vault deploy-rs];
      text = ''
        tmp=$(mktemp -d)
        keypath="$tmp/id_ed25519"
        ssh-keygen -t ed25519 -f "$keypath" -N ""
        vault write \
          -field=signed_key \
          ssh-client-signer/sign/homelab-client \
          "public_key=@$keypath.pub" \
          valid_principals=matt \
          >"$keypath-cert.pub"
        function finish {
          rm -rf "$tmp"
        }
        trap finish EXIT

        deploy --skip-checks --ssh-opts="-i $keypath" "$@"
      '';
    });

    apps.ci-deploy.program = lib.getExe (pkgs.writeShellApplication {
      name = "ci-deploy";
      runtimeInputs = [pkgs.coreutils pkgs.openssh pkgs.vault deploy-rs];
      text = ''
        VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
        export VAULT_TOKEN

        tmp=$(mktemp -d)
        keypath="$tmp/id_ed25519"
        ssh-keygen -t ed25519 -f "$keypath" -N ""
        vault write \
          -field=signed_key \
          ssh-client-signer/sign/homelab-client \
          "public_key=@$keypath.pub" \
          valid_principals=matt \
          >"$keypath-cert.pub"
        function finish {
          rm -rf "$tmp"
        }
        trap finish EXIT

        if [ "$ARCH" = "x86_64" ]; then
          targets=(.#aion .#alecto .#cronus .#gaia .#helios .#megaera .#nemesis .#orion .#phoebe .#rhea .#thanatos .#themis .#tisiphone .#hypnos)
        elif [ "$ARCH" = "arm64" ]; then
          # deploy to arges first, because it may need to reload the gitlab-runner, which fails if
          # the ingress is unavailable, which might temporarily happen when deploying to the other
          # hosts.
          targets=(.#arges .#nyx .#brontes .#steropes)
        fi
        deploy --skip-checks --ssh-opts="-i $keypath" --targets "''${targets[@]}"
      '';
    });
  };
}
