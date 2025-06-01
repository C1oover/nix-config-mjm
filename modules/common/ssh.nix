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
  cfg = config.cloover.ssh;

  sshTrustedKeys = builtins.fetchurl {
    url = "https://vault.midna.dev/v1/ssh-client-signer/public_key";
    sha256 = "12kcpl2mnfds458fv0c0jb0lz122q9jd7vqcfc7cw27giqis2dgl";
  };
  sshHostCA = builtins.fetchurl {
    url = "https://vault.midna.dev/v1/ssh-host-signer/public_key";
    sha256 = "1zy0wvd26iaypwf7zpvdxfhmabdg191q4986aw993j23q87z3g59";
  };

  groupedNodes = pipe nodes [
    attrValues
    (filter (
      n: n.config.deployment.targetHost != null && n.config.deployment.targetUser != config.cloover.username
    ))
    (groupBy (n: n.config.deployment.targetUser))
  ];
in
{
  options.cloover.ssh = {
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
    };

    programs.ssh.extraConfig =
      ''
        CanonicalizeHostname yes
        CanonicalDomains home.mattmoriarity.com

      ''
      + concatMapAttrsStringSep "\n\n" (user: nodes: ''
        Host ${concatMapStringsSep " " (n: n.config.deployment.targetHost) nodes}
          User ${user}
      '') groupedNodes;
  };
}
