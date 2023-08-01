let
  sshTrustedKeys = builtins.fetchurl {
    url = "http://vault.service.consul:8200/v1/ssh-client-signer/public_key";
    sha256 = "12kcpl2mnfds458fv0c0jb0lz122q9jd7vqcfc7cw27giqis2dgl";
  };
in {
  services.openssh = {
    enable = true;
    extraConfig = ''
      TrustedUserCAKeys ${sshTrustedKeys}
    '';
  };
}
