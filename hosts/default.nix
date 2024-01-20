{
  self,
  lib,
  inputs,
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
      chaos = mkNixos [./chaos];
      leto = mkNixos [./leto];

      # Proxmox LXC containers
      rhea = mkNixos [./rhea];
      cronus = mkNixos [./cronus];
      themis = mkNixos [./themis];
    };

    colmena = {
      meta = {
        nixpkgs = inputs.nixos.legacyPackages.x86_64-linux;
        nodeNixpkgs = lib.genAttrs ["arges" "brontes" "steropes"] (_node: inputs.nixos.legacyPackages.aarch64-linux);
        specialArgs = {inherit inputs outputs;};
      };

      defaults = {config, ...}: {
        deployment = {
          targetHost = "${config.networking.hostName}.home.mattmoriarity.com";
          targetUser = "matt";
        };
      };

      arges = {
        deployment.tags = ["builder"];
        imports = [./arges];
      };
      brontes = {
        deployment.tags = ["arm64" "nomad" "ingress"];
        imports = [./brontes];
      };
      steropes = {
        deployment.tags = ["arm64" "nomad" "ingress"];
        imports = [./steropes];
      };

      alecto = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./alecto];
      };
      megaera = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./megaera];
      };
      tisiphone = {
        deployment.tags = ["x86_64" "hashistack"];
        imports = [./tisiphone];
      };

      chaos = {
        deployment.tags = ["x86_64" "garage"];
        imports = [./chaos];
      };
      helios = {
        deployment.tags = ["x86_64" "garage" "nomad"];
        imports = [./helios];
      };
      hypnos = {
        deployment.tags = ["builder"];
        imports = [./hypnos];
      };
      leto = {
        deployment.tags = ["x86_64" "garage"];
        imports = [./leto];
      };

      rhea = {
        deployment.tags = ["x86_64" "dns"];
        imports = [./rhea];
      };
      cronus = {
        deployment.tags = ["x86_64" "dns"];
        imports = [./cronus];
      };
      themis = {
        deployment.tags = ["x86_64"];
        imports = [./themis];
      };
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
        alecto = mkNode "alecto" {};
        arges = mkNode "arges" {};
        brontes = mkNode "brontes" {};
        chaos = mkNode "chaos" {};
        cronus = mkNode "cronus" {};
        helios = mkNode "helios" {};
        hypnos = mkNode "hypnos" {};
        leto = mkNode "leto" {};
        megaera = mkNode "megaera" {};
        nyx = mkNode "nyx" {
          hostname = "nyx.mattmoriarity.com";
        };
        rhea = mkNode "rhea" {};
        steropes = mkNode "steropes" {};
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
    attic = inputs'.attic.packages.default;
  in {
    devenv.shells.default = {
      packages = [pkgs.colmena deploy-rs];
    };

    apps =
      builtins.mapAttrs (_: script: {program = script;}) (pkgs.callPackages ./scripts.nix {
        inherit attic;
      })
      // {
        deploy.program = lib.getExe (pkgs.writeShellApplication {
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

        ci-deploy.program = lib.getExe (pkgs.writeShellApplication {
          name = "ci-deploy";
          runtimeInputs = [pkgs.coreutils pkgs.openssh pkgs.vault deploy-rs attic];
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
              targets=(.#alecto .#cronus .#chaos .#helios .#leto .#megaera .#rhea .#themis .#tisiphone .#hypnos)
            elif [ "$ARCH" = "arm64" ]; then
              # deploy to arges first, because it may need to reload the gitlab-runner, which fails if
              # the ingress is unavailable, which might temporarily happen when deploying to the other
              # hosts.
              targets=(.#arges .#nyx .#brontes .#steropes)
            fi

            deploy --skip-checks --ssh-opts="-i $keypath" --keep-result -r ./result --targets "''${targets[@]}"
            attic push homelab result/*/system
          '';
        });
      };
  };
}
