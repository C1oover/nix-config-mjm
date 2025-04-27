{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.mjm.desktop;

  nixos-cosmic =
    (import
      (
        let
          lock = builtins.fromJSON (builtins.readFile (inputs.cosmic + "/flake.lock"));
        in
        fetchTarball {
          url = "https://github.com/nix-community/flake-compat/archive/${
            lock.nodes.${lock.nodes.${lock.root}.inputs.flake-compat}.locked.rev
          }.tar.gz";
          sha256 = lock.nodes.flake-compat.locked.narHash;
        }
      )
      {
        # hack to skip fetchGit when evaluating impurely and get original paths
        src = {
          outPath = inputs.cosmic.outPath;
        };
      }
    ).defaultNix;
in
{
  imports = [
    nixos-cosmic.nixosModules.default
  ];

  options.mjm.desktop = {
    cosmic = {
      enable = mkEnableOption "COSMIC desktop environment";
    };
  };

  config = mkMerge [
    {
      nix.settings = {
        substituters = [ "https://cosmic.cachix.org/" ];
        trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
      };
    }
    (mkIf (cfg.enable && cfg.cosmic.enable) {
      services.displayManager.cosmic-greeter.enable = true;
      services.desktopManager.cosmic.enable = true;

      # want to login with password so it unlocks the keyring
      security.pam.services.login.fprintAuth = false;
      security.pam.services.cosmic-greeter.fprintAuth = false;
      security.pam.services.greetd.fprintAuth = false;
      security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      programs.gnupg.agent.enable = true;
      programs.seahorse.enable = true;
    })
  ];
}
