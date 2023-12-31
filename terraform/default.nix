{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    terraform = pkgs.opentofu.withPlugins (p: [
      p.consul
      p.gitlab
      p.minio
      p.nomad
      p.vault
      p.cloudflare
      (p.mkProvider {
        owner = "Telmate";
        repo = "terraform-provider-proxmox";
        rev = "v2.9.14";
        spdx = "MIT";
        hash = "sha256-ikXLLNoAjrnGGGI3fHTKFXm8YwqNazE/U39JTjOBsW4=";
        vendorHash = "sha256-um4iOwYO6ASv9wpu5Jua9anUZBKly4yVgI224Fk2dOM=";
        homepage = "https://registry.terraform.io/providers/Telmate/proxmox";
      })
    ]);
    terraformConfiguration =
      (lib.evalModules {
        modules = [
          {_module.args.pkgs = pkgs;}
          ../apps
          {terraform = ./config.nix;}
        ];
        specialArgs = {inherit inputs;};
      })
      .config
      .terraformConfig
      .json;
  in {
    packages.terraform = terraform;

    devenv.shells.default = {
      env = {
        CONSUL_HTTP_ADDR = "consul.service.consul:8500";
        NOMAD_ADDR = "http://nomad.service.consul:4646";
        VAULT_ADDR = "http://vault.service.consul:8200";
      };

      packages = with pkgs; [
        vault
        openssh
      ];

      languages.terraform.enable = true;
      languages.terraform.package = terraform;

      scripts.tf.exec = ''
        cd terraform
        ${lib.getExe terraform} "$@"
      '';
    };

    apps.tf-plan.program = lib.getExe (pkgs.writeShellApplication {
      name = "tf-plan";
      runtimeInputs = [terraform];
      text = ''
        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu plan "$@"
      '';
    });

    apps.tf-apply.program = lib.getExe (pkgs.writeShellApplication {
      name = "tf-apply";
      runtimeInputs = [terraform];
      text = ''
        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu apply "$@"
      '';
    });

    apps.ci-terraform-apply.program = lib.getExe (pkgs.writeShellApplication {
      name = "ci-terraform-apply";
      runtimeInputs = [terraform pkgs.vault];
      text = ''
        VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
        export VAULT_TOKEN

        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu apply -auto-approve
      '';
    });
  };
}
