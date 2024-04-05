let
  sshTrustedKeys = builtins.fetchurl {
    url = "http://vault.service.consul:8200/v1/ssh-client-signer/public_key";
    sha256 = "12kcpl2mnfds458fv0c0jb0lz122q9jd7vqcfc7cw27giqis2dgl";
  };
  sshHostCA = builtins.fetchurl {
    url = "http://vault.service.consul:8200/v1/ssh-host-signer/public_key";
    sha256 = "1zy0wvd26iaypwf7zpvdxfhmabdg191q4986aw993j23q87z3g59";
  };
in
{
  services.openssh = {
    enable = true;
    extraConfig = ''
      TrustedUserCAKeys ${sshTrustedKeys}
    '';
  };

  programs.ssh.knownHosts."*.home.mattmoriarity.com" = {
    publicKeyFile = "${sshHostCA}";
    certAuthority = true;
  };

  programs.ssh.extraConfig = ''
    CanonicalizeHostname yes
    CanonicalDomains home.mattmoriarity.com
  '';
}
