{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.state;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.mjm.state = {
    enableImpermanence = mkEnableOption "impermanence";

    persistDir = mkOption { type = types.path; };

    directories = mkOption {
      type = types.listOf (
        types.coercedTo types.str (d: { directory = d; }) (
          types.submodule {
            options = {
              directory = mkOption { type = types.str; };
              user = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              group = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              mode = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          }
        )
      );
      default = [ ];
    };

    files = mkOption {
      type = types.listOf (
        types.coercedTo types.str (f: { file = f; }) (
          types.submodule {
            options = {
              file = mkOption { type = types.str; };
              user = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              group = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              mode = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          }
        )
      );
      default = [ ];
    };
  };

  config = mkIf cfg.enableImpermanence {
    age.identityPaths = [ "${cfg.persistDir}/etc/ssh/ssh_host_ed25519_key" ];

    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';

    environment.persistence.${cfg.persistDir} = {
      directories = map (filterAttrs (_: v: v != null)) cfg.directories;
      files = map (filterAttrs (_: v: v != null)) cfg.files;

      # TODO abstract this
      users.matt.directories = [ ".local/share/atuin" ];

      hideMounts = mkIf config.mjm.desktop.enable true;
    };

    mjm.state.files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
