{
  bash,
  resholve,
  vault,
  openssh,
  kitty,
  sshPublicKeyPath,
}:
let
  interpreter = "${bash}/bin/bash";

  sshCertPath = builtins.replaceStrings [ ".pub" ] [ "-cert.pub" ] sshPublicKeyPath;

  update-ssh-cert =
    resholve.writeScriptBin "update-ssh-cert"
      {
        inherit interpreter;
        inputs = [ vault ];
        execer = [ "cannot:${vault}/bin/vault" ];
      }
      ''
        vault write \
          -field=signed_key \
          ssh-client-signer/sign/homelab-client \
          public_key=@${sshPublicKeyPath} \
          valid_principals=matt,root \
          >"${sshCertPath}"
      '';
in
{
  vssh =
    resholve.writeScriptBin "vssh"
      {
        inherit interpreter;
        inputs = [
          openssh
          update-ssh-cert
        ];
        execer = [ "cannot:${openssh}/bin/ssh" ];
      }
      ''
        update-ssh-cert
        ssh -i "${sshCertPath}" "$@"
      '';

  s =
    resholve.writeScriptBin "s"
      {
        inherit interpreter;
        inputs = [
          update-ssh-cert
          kitty
        ];
        execer = [ "cannot:${kitty}/bin/kitty" ];
      }
      ''
        update-ssh-cert
        kitty +kitten ssh -i "${sshCertPath}" "$@"
      '';
}
