{ config, lib, ... }:
let
  inherit (lib)
    mkDefault
    mkOption
    types
    ;
in
{
  options.deployment = {
    # copied from colmena's module
    targetHost = lib.mkOption {
      description = ''
        The target SSH node for deployment.

        By default, the node's attribute name will be used.
        If set to null, only local deployment will be supported.
      '';
      type = types.nullOr types.str;
      default = config.networking.hostName;
    };
    targetUser = lib.mkOption {
      description = ''
        The user to use to log into the remote node. If set to null, the
        target user will not be specified in SSH invocations.
      '';
      type = types.nullOr types.str;
      default = "root";
    };
    tags = lib.mkOption {
      description = ''
        A list of tags for the node.

        Can be used to select a group of nodes for deployment.
      '';
      type = types.listOf types.str;
      default = [ ];
    };

    consulChecks = mkOption {
      description = ''
        The names of Consul services that must be passing health checks in order for
        deploying this host to be considered successful.
      '';
      type = types.listOf types.str;
      default = [ ];
    };
    rebootAutomatically = mkOption {
      description = ''
        Whether this host can be rebooted automatically during a deploy.

        If not, then when a reboot is determined to be necessary, the `boot` goal
        will be used, but then the host will need to rebooted manually to apply it.
      '';
      type = types.bool;
      default = true;
    };
    tests = mkOption {
      description = ''
        NixOS tests that should be run before deploying to this host.
      '';
      type = types.attrsOf types.package;
      default = { };
    };
  };

  config = {
    deployment = {
      targetHost = mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
      targetUser = config.mjm.username;
    };
  };
}
