let
  sshTrustedKeys = builtins.fetchurl "http://vault.service.consul:8200/v1/ssh-client-signer/public_key";
in
{
  services.openssh = {
    enable = true;
    extraConfig = ''
      TrustedUserCAKeys ${sshTrustedKeys}
    '';
  };
}
