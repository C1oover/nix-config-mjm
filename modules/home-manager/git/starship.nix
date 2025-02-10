{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.git;
in
{
  config = mkIf (cfg.enable && cfg.desktop.enable) {
    programs.starship.settings = {
      git_branch.only_attached = true;
      git_commit.disabled = true;
      git_status.disabled = true;
      custom =
        let
          sd = lib.getExe pkgs.sd;
          mkStatusModule =
            {
              variable,
              style,
              symbol,
            }:
            {
              command = ''
                jj log -r@ -n 1 --no-graph -T "" --stat | tail -n1 | ${sd} "(\\d+) files? changed, (\\d+) insertions?\\(\\+\\), (\\d+) deletions?\\(-\\)" "''${${variable}}" | ${sd} "0" ""
              '';
              format = "[( ${symbol}$output)]($style)";
              style = "italic dimmed ${style}";
              detect_folders = [ ".jj" ];
            };
        in
        {
          jj = {
            command = ''
              jj log -r@ --no-graph --color always -T '
                label("working_copy",
                  concat(
                    separate(" ",
                      if(conflict, label("conflict", "conflict")),
                      if(empty, label("empty", "(empty)")),
                      if(description, description.first_line(), label(if(empty, "empty"), description_placeholder))
                    )
                  )
                )
              '
            '';
            style = "";
            detect_folders = [ ".jj" ];
            symbol = " @ ";
          };
          jj_added = mkStatusModule {
            variable = "2";
            style = "green";
            symbol = "▴";
          };
          jj_removed = mkStatusModule {
            variable = "3";
            style = "red";
            symbol = "▿";
          };
        };
    };
  };
}
