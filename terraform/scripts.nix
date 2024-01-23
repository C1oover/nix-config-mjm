{
  lib,
  bash,
  resholve,
  coreutils,
  vault,
  opentofu,
  terraformConfiguration,
}:
let
  interpreter = "${bash}/bin/bash";
in
{
  tf-plan =
    resholve.writeScript "tf-plan"
      {
        inherit interpreter;
        inputs = [
          opentofu
          coreutils
        ];
        execer = [ "cannot:${opentofu}/bin/tofu" ];
      }
      ''
        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu plan "$@"
      '';

  tf-apply =
    resholve.writeScript "tf-apply"
      {
        inherit interpreter;
        inputs = [
          opentofu
          coreutils
        ];
        execer = [ "cannot:${opentofu}/bin/tofu" ];
      }
      ''
        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu apply "$@"
      '';

  ci-terraform-apply =
    resholve.writeScript "ci-terraform-apply"
      {
        inherit interpreter;
        inputs = [
          opentofu
          coreutils
          vault
        ];
        execer = [
          "cannot:${vault}/bin/vault"
          "cannot:${opentofu}/bin/tofu"
        ];
      }
      ''
        VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
        export VAULT_TOKEN

        cd terraform
        ln -sf ${terraformConfiguration} config.tf.json
        tofu init && tofu apply -auto-approve
      '';
}
