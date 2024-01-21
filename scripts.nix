{
  bash,
  resholve,
  curl,
  jq,
  nix,
  git,
}: let
  interpreter = "${bash}/bin/bash";
in {
  ci-flake-update = resholve.writeScriptBin "ci-flake-update" {
    inherit interpreter;
    inputs = [curl jq nix git];
    execer = ["cannot:${nix}/bin/nix" "cannot:${git}/bin/git"];
  } (builtins.readFile ./flake-update.sh);
}
