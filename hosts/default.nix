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
    inputs.nixpkgs.lib.nixosSystem {
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
    system,
    ...
  }: let
    deploy-rs = inputs.deploy-rs.packages.${system}.default;
  in {
    devenv.shells.default = {
      packages = [deploy-rs];
    };

    apps.deploy.program = toString (pkgs.writeShellScript "deploy" ''
      tmp=$(${pkgs.coreutils}/bin/mktemp -d)
      keypath="$tmp/id_ed25519"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$keypath" -N ""
      ${pkgs.vault}/bin/vault write \
        -field=signed_key \
        ssh-client-signer/sign/homelab-client \
        "public_key=@$keypath.pub" \
        valid_principals=matt \
        >"$keypath-cert.pub"
      function finish {
        rm -rf "$tmp"
      }
      trap finish EXIT

      ${deploy-rs}/bin/deploy --skip-checks --ssh-opts="-i $keypath" "$@"
    '');

    apps.ci-deploy.program = toString (pkgs.writeShellScript "ci-deploy" ''
      export VAULT_TOKEN=$(${pkgs.vault}/bin/vault write -field=token auth/gitlab/login role=homelab-infra jwt=$VAULT_ID_TOKEN)
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /tmp/id_ed25519 -N ""
      ${pkgs.vault}/bin/vault write \
        -field=signed_key \
        ssh-client-signer/sign/homelab-client \
        public_key=@/tmp/id_ed25519.pub \
        valid_principals=matt \
        >/tmp/id_ed25519-cert.pub

      if [ "$ARCH" = "x86_64" ]; then
        targets=".#aion .#alecto .#cronus .#gaia .#helios .#megaera .#nemesis .#orion .#phoebe .#rhea .#thanatos .#themis .#tisiphone .#hypnos"
      elif [ "$ARCH" = "arm64" ]; then
        targets=".#brontes .#nyx .#steropes .#arges"
      fi
      ${deploy-rs}/bin/deploy --skip-checks --ssh-opts="-o StrictHostKeyChecking=no -i /tmp/id_ed25519" --targets $targets
    '');
  };
}
