{
  pkgs,
  lib,
  config,
  nodes,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMapAttrsStringSep
    concatMapStringsSep
    filter
    groupBy
    mkEnableOption
    mkIf
    mkOption
    pipe
    types
    ;
  cfg = config.mjm.ssh;

  sshTrustedKeys = builtins.fetchurl {
    url = "http://vault.service.consul:8200/v1/ssh-client-signer/public_key";
    sha256 = "12kcpl2mnfds458fv0c0jb0lz122q9jd7vqcfc7cw27giqis2dgl";
  };
  sshHostCA = builtins.fetchurl {
    url = "http://vault.service.consul:8200/v1/ssh-host-signer/public_key";
    sha256 = "1zy0wvd26iaypwf7zpvdxfhmabdg191q4986aw993j23q87z3g59";
  };

  groupedNodes = pipe nodes [
    attrValues
    (filter (
      n: n.config.deployment.targetHost != null && n.config.deployment.targetUser != config.mjm.username
    ))
    (groupBy (n: n.config.deployment.targetUser))
  ];
in
{
  options.mjm.ssh = {
    enable = mkEnableOption "SSH config" // {
      default = true;
    };

    trustedKeys = mkOption {
      type = types.path;
      default = sshTrustedKeys;
    };

    hostCA = mkOption {
      type = types.path;
      default = sshHostCA;
    };
  };

  config = mkIf cfg.enable {
    # used for kitty ssh integration
    environment.systemPackages = [ pkgs.python3 ];

    programs.ssh.knownHosts = {
      "*.home.mattmoriarity.com" = {
        publicKeyFile = "${sshHostCA}";
        certAuthority = true;
      };
      aion = {
        hostNames = [
          "aion"
          "5.78.46.61"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUWju/ZTNyivso/yzx6RFE/9D50qTiWVXDvITrkyEVh";
      };
      proxmox = {
        hostNames = [ "*.home.mattmoriarity.com" ];
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3vy++Xj7QpqRrSviH4zRlzcuWzx+beCsEw8tFNKiYZrYffZhWeoNmZ1/UtbDSb48wD2HiYEemqyMUOXXsxtSTDNIFF/+m4itrBvbabCfOUPxjrLONrd82t9OmgrbPOg+MKSa4+mPlGjxnIZfcX50coMlUpamMUTzXtqTublYtQjsPEkVxsRACGEBtqZ/l/ccOQL0jnxV6+WP1Yk2hYu13vpkBPkxtuBh3F6aA81ur9h1u2glfI9+3SnytSRinoTLnAdYdl8TOHrpMf7iuz+YQ/QX5CIFPRJLSA2UKP5UxHC/Zqg8BadiTL1my0nIHpzqyskIhnUiXFHetPRrmvAtryAcIQhvtnLXt6S4p4xob1bIZPeeDlKVH9piX5NwMdV+Cm0DWV3zSkJF9a6j1wAoAFDFU/veeo2bTNiNQYgGRn0+hwdJLf/0h8SUqBsdsaYnvp/CECFZfVqDkvegAkhdtmyWTPcjQMDi+C6TNaCwNm3HA0a+7jHnD8ExN2RgBBtjS1sYaomvW2eE3/h4XmFRXyMRhr6xoAbBvRPZ5SxAnS3X/mIK5Z+kuWlMCz3kKTerlF+rOxM2IsI9H14eNC443PQX2Ot/drtHC3XDRfi1oQNTTrkCg3sulqz1TcXzqGRRiGG0NlOIVV6qbp6WuVS0Gq6VTxIwf0V9KPUSB0vp3vQ==";
        certAuthority = true;
      };
    };

    programs.ssh.extraConfig =
      ''
        CanonicalizeHostname yes
        CanonicalDomains home.mattmoriarity.com

        Host aion
          Hostname 5.78.46.61

        # Logic below only covers NixOS nodes, not nix-darwin
        # TODO fix if nixos-deploy gets darwin support
        Host talos.home.mattmoriarity.com
          User mjm

      ''
      + concatMapAttrsStringSep "\n\n" (user: nodes: ''
        Host ${concatMapStringsSep " " (n: n.config.deployment.targetHost) nodes}
          User ${user}
      '') groupedNodes;
  };
}
