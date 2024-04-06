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

  programs.ssh.knownHosts = {
    "*.home.mattmoriarity.com" = {
      publicKeyFile = "${sshHostCA}";
      certAuthority = true;
    };
    proxmox = {
      hostNames = [ "*.home.mattmoriarity.com" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3vy++Xj7QpqRrSviH4zRlzcuWzx+beCsEw8tFNKiYZrYffZhWeoNmZ1/UtbDSb48wD2HiYEemqyMUOXXsxtSTDNIFF/+m4itrBvbabCfOUPxjrLONrd82t9OmgrbPOg+MKSa4+mPlGjxnIZfcX50coMlUpamMUTzXtqTublYtQjsPEkVxsRACGEBtqZ/l/ccOQL0jnxV6+WP1Yk2hYu13vpkBPkxtuBh3F6aA81ur9h1u2glfI9+3SnytSRinoTLnAdYdl8TOHrpMf7iuz+YQ/QX5CIFPRJLSA2UKP5UxHC/Zqg8BadiTL1my0nIHpzqyskIhnUiXFHetPRrmvAtryAcIQhvtnLXt6S4p4xob1bIZPeeDlKVH9piX5NwMdV+Cm0DWV3zSkJF9a6j1wAoAFDFU/veeo2bTNiNQYgGRn0+hwdJLf/0h8SUqBsdsaYnvp/CECFZfVqDkvegAkhdtmyWTPcjQMDi+C6TNaCwNm3HA0a+7jHnD8ExN2RgBBtjS1sYaomvW2eE3/h4XmFRXyMRhr6xoAbBvRPZ5SxAnS3X/mIK5Z+kuWlMCz3kKTerlF+rOxM2IsI9H14eNC443PQX2Ot/drtHC3XDRfi1oQNTTrkCg3sulqz1TcXzqGRRiGG0NlOIVV6qbp6WuVS0Gq6VTxIwf0V9KPUSB0vp3vQ==";
      certAuthority = true;
    };
  };

  programs.ssh.extraConfig = ''
    CanonicalizeHostname yes
    CanonicalDomains home.mattmoriarity.com

    Host apollo.home.mattmoriarity.com artemis.home.mattmoriarity.com hades.home.mattmoriarity.com
      User root
  '';
}
