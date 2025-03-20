{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    attrValues
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.mjm.git;

  git-scripts = pkgs.callPackage ./scripts { };
in
{
  imports = [
    ./jujutsu.nix
    ./starship.nix
  ];

  options.mjm.git = {
    enable = mkEnableOption "Git configuration";
    desktop.enable = mkEnableOption "tools and config only needed for workstations";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.git = {
        enable = true;
        aliases = {
          st = "status -sb";
          ci = "commit --verbose";
          di = "diff";
          dc = "diff --cached";
        };
        extraConfig = {
          push = {
            default = "simple";
            autoSetupRemote = true;
          };
          help.autocorrect = 10;
          pull.rebase = false;
        };
        userName = "Matt Moriarity";
        userEmail = mkDefault "matt@mattmoriarity.com";
      };
    }

    (mkIf cfg.desktop.enable {
      home.packages = attrValues {
        inherit git-scripts;
        inherit (pkgs)
          glab
          git-credential-manager
          ;
      };

      programs.git.extraConfig = {
        credential = {
          helper = [
            "" # important: need to unset the default osx one on macOS, or it will mess up refreshing GitLab tokens
            "manager"
          ];
          credentialStore = mkIf pkgs.stdenv.isLinux "secretservice";
          "https://git.midna.dev" = {
            gitLabDevClientId = "2c4d82734ab055ae7ef0d2b1d1a596170d87e28ef4578a99de8298bdfdae52e9";
            gitLabDevClientSecret = "f4a3f4ef523cc1a20313464ba0a48d6185a11247f4c66091229760284685b1c5";
            provider = "gitlab";
          };
        };
      };
    })
  ]);
}
