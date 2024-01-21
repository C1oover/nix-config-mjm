{
  lib,
  bash,
  resholve,
  coreutils,
  openssh,
  vault,
  attic,
  colmena,
}: let
  interpreter = "${bash}/bin/bash";

  ci-vault-login =
    resholve.writeScript "ci-vault-login" {
      inherit interpreter;
      inputs = [vault];
      execer = ["cannot:${vault}/bin/vault"];
    } ''
      VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
      export VAULT_TOKEN
    '';

  create-temp-key =
    resholve.writeScript "create-temp-key" {
      inherit interpreter;
      inputs = [coreutils openssh vault];
      execer = ["cannot:${openssh}/bin/ssh-keygen" "cannot:${vault}/bin/vault"];
    } ''
      SSH_KEY_DIR=$(mktemp -d)
      SSH_KEY_PATH="$SSH_KEY_DIR/id_ed25519"
      ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""
      vault write \
        -field=signed_key \
        ssh-client-signer/sign/homelab-client \
        "public_key=@$SSH_KEY_PATH.pub" \
        valid_principals=matt \
        >"$SSH_KEY_PATH-cert.pub"
      function finish {
        rm -rf "$SSH_KEY_DIR"
      }
      trap finish EXIT
    '';
in {
  unseal =
    resholve.writeScriptBin "unseal" {
      inherit interpreter;
      inputs = [vault];
      fake.external = ["op"];
      execer = ["cannot:${vault}/bin/vault"];
    } ''
      host="$1"
      export VAULT_ADDR="http://$host:8200"

      vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/638880CCF1664DED95BB219A708A896A")"
      vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/979343926DF44A88B93808C49CE2FE26")"
      vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/368F61C90CD34E2BBDF03F02C314AA1D")"
    '';

  ci-attic-login =
    resholve.writeScriptBin "ci-attic-login" {
      inherit interpreter;
      inputs = [vault attic];
      keep.source = ["${ci-vault-login}"];
      execer = ["cannot:${vault}/bin/vault"];
    } ''
      source ${ci-vault-login}

      ATTIC_TOKEN=$(vault kv get -field=token kv/attic/client)
      attic login --set-default homelab https://attic.midna.dev "$ATTIC_TOKEN"

      # ensure attic itself gets cached, since it's expensive to build
      attic push homelab ${attic}
    '';

  deploy =
    resholve.writeScriptBin "deploy" {
      inherit interpreter;
      inputs = [coreutils colmena];
      keep.source = ["${create-temp-key}"];
      execer = ["cannot:${colmena}/bin/colmena"];
    } ''
      source ${create-temp-key}

      config_file="$SSH_KEY_DIR/ssh_config"
      cat >"$config_file" <<EOF
      IdentityFile $SSH_KEY_PATH
      Host *
        UserKnownHostsFile ~/.ssh/known_hosts
      EOF

      export SSH_CONFIG_FILE="$config_file"
      colmena apply "$@"
    '';

  ci-deploy =
    resholve.writeScriptBin "ci-deploy-colmena" {
      inherit interpreter;
      inputs = [coreutils colmena attic];
      keep.source = ["${ci-vault-login}" "${create-temp-key}"];
      execer = ["cannot:${colmena}/bin/colmena"];
    } ''
      source ${ci-vault-login}
      source ${create-temp-key}

      config_file="$SSH_KEY_DIR/ssh_config"
      cat >"$config_file" <<EOF
      IdentityFile $SSH_KEY_PATH
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
}
