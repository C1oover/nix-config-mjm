{
  lib,
  bash,
  resholve,
  coreutils,
  kitty,
}:
let
  interpreter = "${bash}/bin/bash";
in
{
  tt =
    resholve.writeScriptBin "tt"
      {
        inherit interpreter;
        inputs = [
          coreutils
          kitty
        ];
        execer = [ "cannot:${kitty}/bin/kitty" ];
      }
      ''
        kitty @ set-tab-title "$(basename "$PWD")"
      '';
}
