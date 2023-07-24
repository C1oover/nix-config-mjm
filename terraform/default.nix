{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    inherit (inputs) terranix;
    terraform = pkgs.terraform.withPlugins (p: [
      p.consul
      p.gitlab
      p.minio
      p.nomad
      p.vault
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
    terraformConfiguration = terranix.lib.terranixConfiguration {
      inherit system;
      modules = [./config.nix];
    };
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
        cd "$(git rev-parse --show-toplevel)/terraform" || exit
        ${terraform}/bin/terraform "$@"
      '';
    };

    apps.tf-plan.program = toString (pkgs.writeShellScript "tf-plan" ''
      cd "$(git rev-parse --show-toplevel)/terraform" || exit
      ln -sf ${terraformConfiguration} config.tf.json
      ${terraform}/bin/terraform init && \
        ${terraform}/bin/terraform plan "$@"
    '');

    apps.tf-apply.program = toString (pkgs.writeShellScript "tf-apply" ''
      cd "$(git rev-parse --show-toplevel)/terraform" || exit
      ln -sf ${terraformConfiguration} config.tf.json
      ${terraform}/bin/terraform init && \
        ${terraform}/bin/terraform apply "$@"
    '');

    apps.ci-terraform-apply.program = toString (pkgs.writeShellScript "ci-terraform-apply" ''
      set -e

      export VAULT_TOKEN=$(${pkgs.vault}/bin/vault write -field=token auth/gitlab/login role=homelab-infra jwt=$VAULT_ID_TOKEN)

      cd "$(git rev-parse --show-toplevel)/terraform" || exit
      ln -sf ${terraformConfiguration} config.tf.json
      ${terraform}/bin/terraform init && \
        ${terraform}/bin/terraform apply -auto-approve
    '');
  };
}
