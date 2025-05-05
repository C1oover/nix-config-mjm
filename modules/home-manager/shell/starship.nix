{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    importTOML
    mkForce
    mkIf
    mkMerge
    ;
  cfg = config.mjm.shell;
in
{
  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = mkMerge [
        {
          command_timeout = 2000;
          os.disabled = true;
          gcloud.disabled = true;
          docker_context.disabled = true;
          terraform.disabled = true;
          git_metrics.disabled = mkForce true;
          sudo.disabled = mkForce true;
          nix_shell.heuristic = true;

          # format = mkForce "($nix_shell$container\${custom.jj}\${custom.jj_added}\${custom.jj_removed}\n)$cmd_duration$hostname$localip$shlvl$shell$env_var$jobs$sudo$username$character";
          format = mkForce "$username$hostname$directory$cmd_duration$line_break$character";
        }
        # (importTOML ./jetpack.toml)
        (importTOML ./pure.toml)
      ];
    };

    catppuccin.starship.enable = true;
  };
}
