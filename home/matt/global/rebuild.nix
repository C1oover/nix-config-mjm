{
  lib,
  stdenv,
  bash,
  resholve,
  nix-output-monitor,
  nvd,
  nettools,
  nix,
  coreutils,
  systemd,
}:
let
  interpreter = "${bash}/bin/bash";
  variant = if stdenv.isLinux then "linux" else "darwin";
in
{
  rb =
    resholve.writeScriptBin ",rb"
      {
        inherit interpreter;
        inputs = [
          nix-output-monitor
          nvd
        ] ++ lib.optional (variant == "linux") nettools;
        fake.external = [ "scutil" ];
        execer = [
          "cannot:${nix-output-monitor}/bin/nom"
          "cannot:${nvd}/bin/nvd"
        ];
      }
      (builtins.readFile ./rebuild.${variant}.sh);

  sw =
    resholve.writeScriptBin ",sw"
      {
        inherit interpreter;
        inputs = [
          nix
          coreutils
        ] ++ lib.optional (variant == "linux") systemd;
        fake.external = [ "sudo" ];
        keep."$PWD" = true;
      }
      (builtins.readFile ./switch.${variant}.sh);
}
