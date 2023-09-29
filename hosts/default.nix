{
  self,
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
    ...
  }: let
    deploy-rs = inputs.deploy-rs.packages.${system}.default;
  in {
    devenv.shells.default = {
      packages = [deploy-rs];
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

        ssh-keygen -t ed25519 -f /tmp/id_ed25519 -N ""
        vault write \
          -field=signed_key \
          ssh-client-signer/sign/homelab-client \
          public_key=@/tmp/id_ed25519.pub \
          valid_principals=matt \
          >/tmp/id_ed25519-cert.pub

        if [ "$ARCH" = "x86_64" ]; then
          targets=(.#aion .#alecto .#cronus .#gaia .#helios .#megaera .#nemesis .#orion .#phoebe .#rhea .#thanatos .#themis .#tisiphone .#hypnos)
        elif [ "$ARCH" = "arm64" ]; then
          # deploy to arges first, because it may need to reload the gitlab-runner, which fails if
          # the ingress is unavailable, which might temporarily happen when deploying to the other
          # hosts.
          targets=(.#arges .#nyx .#brontes .#steropes)
        fi
        deploy --skip-checks --ssh-opts="-i /tmp/id_ed25519" --targets "''${targets[@]}"
      '';
    });
  };
}
