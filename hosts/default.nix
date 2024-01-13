{
  self,
  lib,
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
      chaos = mkNixos [./chaos];
      leto = mkNixos [./leto];

      # Proxmox LXC containers
      rhea = mkNixos [./rhea];
      cronus = mkNixos [./cronus];
      themis = mkNixos [./themis];
      thanatos = mkNixos [./thanatos];

      ingresstest = mkNixos [./ingresstest];
    };

    checks = let
      mkDeployCheck = system: nodes:
        withSystem system (
          {pkgs, ...}:
            pkgs.linkFarm "deploy-${system}"
            (pkgs.lib.genAttrs nodes (name: outputs.deploy.nodes.${name}.profiles.system.path))
        );
    in {
      x86_64-linux.deploy-1 = mkDeployCheck "x86_64-linux" ["aion" "cronus" "gaia" "nemesis" "orion"];
      x86_64-linux.deploy-2 = mkDeployCheck "x86_64-linux" ["phoebe" "rhea" "thanatos" "themis"];
      x86_64-linux.deploy-3 = mkDeployCheck "x86_64-linux" ["alecto" "helios" "hypnos" "megaera" "tisiphone"];
      aarch64-linux.deploy = mkDeployCheck "aarch64-linux" ["arges" "brontes" "nyx" "steropes"];
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
      thanatos = {
        deployment.tags = ["x86_64"];
        imports = [./thanatos];
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
    attic = inputs'.attic.packages.default;
  in {
    devenv.shells.default = {
      packages = [pkgs.colmena deploy-rs];
    };

    apps.unseal.program = lib.getExe (pkgs.writeShellApplication {
      name = "unseal";
      # _1password intentionally left out since it goes through a security wrapper for setgid
      runtimeInputs = [pkgs.vault];
      text = ''
        host="$1"
        export VAULT_ADDR="http://$host:8200"

        vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/638880CCF1664DED95BB219A708A896A")"
        vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/979343926DF44A88B93808C49CE2FE26")"
        vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/368F61C90CD34E2BBDF03F02C314AA1D")"
      '';
    });

    apps.ci-attic-login.program = lib.getExe (pkgs.writeShellApplication {
      name = "ci-attic-login";
      runtimeInputs = [pkgs.vault attic];
      text = ''
        VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
        export VAULT_TOKEN

        ATTIC_TOKEN=$(vault kv get -field=token kv/attic/client)
        attic login --set-default homelab https://attic.midna.dev "$ATTIC_TOKEN"

        # ensure attic itself gets cached, since it's expensive to build
        attic push homelab ${attic}
      '';
    });

    packages.deploy-prebuild = pkgs.writeShellApplication {
      name = "deploy-prebuild";
      runtimeInputs = [inputs'.nix-fast-build.packages.default attic];
      text = ''
        if [ "$1" = "arm64" ]; then
          shift
          nix-fast-build -f ".#checks.aarch64-linux.deploy" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          attic push homelab ./result
        else
          shift
          nix-fast-build -f ".#checks.x86_64-linux.deploy-1" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          attic push homelab ./result
          nix-fast-build -f ".#checks.x86_64-linux.deploy-2" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          attic push homelab ./result
          nix-fast-build -f ".#checks.x86_64-linux.deploy-3" --eval-max-memory-size 2048 --eval-workers 4 "$@"
          attic push homelab ./result
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

    apps.deploy-colmena.program = lib.getExe (pkgs.writeShellApplication {
      name = "deploy-colmena";
      runtimeInputs = [pkgs.coreutils pkgs.colmena pkgs.openssh pkgs.vault];
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

        config_file="$tmp/ssh_config"
        cat >"$config_file" <<EOF
        IdentityFile $keypath
        Host *
          UserKnownHostsFile ~/.ssh/known_hosts
        EOF

        export SSH_CONFIG_FILE="$config_file"
        colmena apply "$@"
      '';
    });

    apps.ci-deploy.program = lib.getExe (pkgs.writeShellApplication {
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
          targets=(.#alecto .#cronus .#chaos .#helios .#leto .#megaera .#rhea .#thanatos .#themis .#tisiphone .#hypnos)
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

    apps.ci-deploy-colmena.program = lib.getExe (pkgs.writeShellApplication {
      name = "ci-deploy-colmena";
      runtimeInputs = [pkgs.coreutils pkgs.openssh pkgs.vault pkgs.colmena attic];
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

        config_file="$tmp/ssh_config"
        cat >"$config_file" <<EOF
        IdentityFile $keypath
        EOF
        export SSH_CONFIG_FILE="$config_file"

        if [ "$ARCH" = "arm64" ]; then
          # deploy to arges first, because it may need to reload the gitlab-runner, which fails if
          # the ingress is unavailable, which might temporarily happen when deploying to the other
          # hosts.
          colmena apply --on arges --keep-result
        fi

        colmena apply --on "@$ARCH" --keep-result

        if [ "$ARCH" = "x86_64" ]; then
          colmena apply --on hypnos --keep-result
        fi

        attic push homelab .gcroots/node-*
      '';
    });
  };
}
