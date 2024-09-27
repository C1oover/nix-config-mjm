{
  lib,
  writers,
  vault,
  openssh,
  kitty,
  sshPublicKeyPath,
}:

let
  sshCertPath = builtins.replaceStrings [ ".pub" ] [ "-cert.pub" ] sshPublicKeyPath;
in
writers.writeNuBin "homelab"
  {
    makeWrapperArgs = [
      "--prefix"
      ":"
      "PATH"
      (lib.makeBinPath [
        vault
        openssh
        kitty
      ])
    ];
  }
  ''
    def update-ssh-cert [] {
      (vault write
        -field=signed_key
        ssh-client-signer/sign/homelab-client
        public_key=@${sshPublicKeyPath}
        valid_principals=matt,root
      ) | save -f "${sshCertPath}"
    }

    def --wrapped "main ssh vault" [...args] {
      update-ssh-cert
      ssh -i "${sshCertPath}" ...$args
    }

    def --wrapped "main ssh kitty" [...args] {
      update-ssh-cert
      (kitty
        +kitten ssh
        -i "${sshCertPath}"
        --kitten interpreter=python3
        ...$args)
    }

    def main [] {}
  ''
