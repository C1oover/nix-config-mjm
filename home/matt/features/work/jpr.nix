{
  bash,
  resholve,
  gh,
}:
resholve.writeScriptBin ",jpr"
  {
    interpreter = "${bash}/bin/bash";
    inputs = [ gh ];
    execer = [ "cannot:${gh}/bin/gh" ];
  }
  ''
    gh pr create --head "$1" --web
  ''
