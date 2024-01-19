{
  bash,
  resholve,
  teleport,
}:
resholve.writeScriptBin "db" {
  interpreter = "${bash}/bin/bash";
  inputs = [teleport];
  execer = ["cannot:${teleport}/bin/tsh"];
} (builtins.readFile ./db.sh)
